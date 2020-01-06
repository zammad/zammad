require 'rails_helper'

RSpec.describe Channel::Driver::Twitter do
  subject(:channel) { create(:twitter_channel) }

  describe '#process', current_user_id: 1 do
    # Twitter channels must be configured to know whose account they're monitoring.
    subject(:channel) do
      create(:twitter_channel, custom_options: { user: { id: payload[:for_user_id] } })
    end

    let(:payload) { YAML.safe_load(File.read(payload_file), [ActiveSupport::HashWithIndifferentAccess]) }

    # https://git.znuny.com/zammad/zammad/-/issues/305
    shared_examples 'for user processing' do
      let(:sender_attributes) do
        {
          'login'        => sender_profile[:screen_name],
          'firstname'    => sender_profile[:name].capitalize,
          'web'          => sender_profile[:url],
          'note'         => sender_profile[:description],
          'address'      => sender_profile[:location],
          'image_source' => sender_profile[:profile_image_url],
        }
      end

      let(:avatar_attributes) do
        {
          'object_lookup_id' => ObjectLookup.by_name('User'),
          'deletable'        => true,
          'source'           => 'twitter',
          'source_url'       => sender_profile[:profile_image_url],
        }
      end

      let(:authorization_attributes) do
        {
          'uid'      => sender_profile[:id],
          'username' => sender_profile[:screen_name],
          'provider' => 'twitter',
        }
      end

      context 'from unknown user' do
        it 'creates a User record for the sender' do
          expect { channel.process(payload) }
            .to change(User, :count).by(1)
            .and change { User.exists?(sender_attributes) }.to(true)
        end

        it 'creates an Avatar record for the sender', :use_vcr do
          # Why 2, and not 1? Avatar.add auto-generates a default (source: 'init') record
          # before actually adding the specified (source: 'twitter') one.
          expect { channel.process(payload) }
            .to change(Avatar, :count).by_at_least(1)
            .and change { Avatar.exists?(avatar_attributes) }.to(true)

          expect(User.last.image).to eq(Avatar.last.store_hash)
        end

        it 'creates an Authorization record for the sender' do
          expect { channel.process(payload) }
            .to change(Authorization, :count).by(1)
            .and change { Authorization.exists?(authorization_attributes) }.to(true)
        end
      end

      context 'from known user' do
        let!(:user) { create(:user) }

        let!(:avatar) { create(:avatar, o_id: user.id, object_lookup_id: ObjectLookup.by_name('User'), source: 'twitter') }

        let!(:authorization) do
          Authorization.create(user_id: user.id, uid: sender_profile[:id], provider: 'twitter')
        end

        it 'updates the sender’s existing User record' do
          expect { channel.process(payload) }
            .to not_change(User, :count)
            .and not_change { user.reload.attributes.slice('login', 'firstname') }
            .and change { User.exists?(sender_attributes.except('login', 'firstname')) }.to(true)
        end

        it 'updates the sender’s existing Avatar record', :use_vcr do
          expect { channel.process(payload) }
            .to not_change(Avatar, :count)
            .and change { Avatar.exists?(avatar_attributes) }.to(true)

          expect(user.reload.image).to eq(avatar.reload.store_hash)
        end

        it 'updates the sender’s existing Authorization record' do
          expect { channel.process(payload) }
            .to not_change(Authorization, :count)
            .and change { Authorization.exists?(authorization_attributes) }.to(true)
        end
      end
    end

    context 'for incoming DM' do
      let(:payload_file) { Rails.root.join('test/data/twitter/webhook_events/direct_message-incoming.yml') }

      include_examples 'for user processing' do
        # Payload sent by Twitter is { ..., users: [{ <uid>: <sender> }, { <uid>: <receiver> }] }
        let(:sender_profile) { payload[:users].values.first }
      end

      describe 'ticket creation' do
        let(:ticket_attributes) do
          # NOTE: missing "customer_id" (because the value is generated as part of the #process method)
          {
            'title'       => title,
            'group_id'    => channel.options[:sync][:direct_messages][:group_id],
            'state'       => Ticket::State.find_by(default_create: true),
            'priority'    => Ticket::Priority.find_by(default_create: true),
            'preferences' => {
              'channel_id'          => channel.id,
              'channel_screen_name' => channel.options[:user][:screen_name],
            },
          }
        end

        let(:title) { payload[:direct_message_events].first[:message_create][:message_data][:text] }

        it 'creates a new ticket' do
          expect { channel.process(payload) }
            .to change(Ticket, :count).by(1)
            .and change { Ticket.exists?(ticket_attributes) }.to(true)
        end

        context 'for duplicate messages' do
          before do
            channel.process(
              YAML.safe_load(File.read(payload_file), [ActiveSupport::HashWithIndifferentAccess])
            )
          end

          it 'does not create duplicate ticket' do
            expect { channel.process(payload) }
              .to not_change(Ticket, :count)
              .and not_change(Ticket::Article, :count)
          end
        end

        context 'for message longer than 80 chars' do
          before { payload[:direct_message_events].first[:message_create][:message_data][:text] = 'a' * 81 }

          let(:title) { "#{'a' * 80}..." }

          it 'creates ticket with truncated title' do
            expect { channel.process(payload) }
              .to change(Ticket, :count).by(1)
              .and change { Ticket.exists?(ticket_attributes) }.to(true)
          end
        end

        context 'in reply to existing thread/ticket' do
          # import parent DM
          before do
            channel.process(
              YAML.safe_load(
                File.read(Rails.root.join('test/data/twitter/webhook_events/direct_message-incoming.yml')),
                [ActiveSupport::HashWithIndifferentAccess]
              )
            )
          end

          let(:payload_file) { Rails.root.join('test/data/twitter/webhook_events/direct_message-incoming_2.yml') }

          it 'uses existing ticket' do
            expect { channel.process(payload) }
              .to not_change(Ticket, :count)
              .and not_change { Ticket.last.state }
          end

          context 'marked "closed" / "merged" / "removed"' do
            before { Ticket.last.update(state: Ticket::State.find_by(name: 'closed')) }

            it 'creates a new ticket' do
              expect { channel.process(payload) }
                .to change(Ticket, :count).by(1)
                .and change { Ticket.exists?(ticket_attributes) }.to(true)
            end
          end

          context 'marked "pending reminder" / "pending close"' do
            before { Ticket.last.update(state: Ticket::State.find_by(name: 'pending reminder')) }

            it 'sets existing ticket to "open"' do
              expect { channel.process(payload) }
                .to not_change(Ticket, :count)
                .and change { Ticket.last.state.name }.to('open')
            end
          end
        end
      end

      describe 'article creation' do
        let(:article_attributes) do
          # NOTE: missing "ticket_id" (because the value is generated as part of the #process method)
          {
            'from'        => "@#{payload[:users].values.first[:screen_name]}",
            'to'          => "@#{payload[:users].values.second[:screen_name]}",
            'body'        => payload[:direct_message_events].first[:message_create][:message_data][:text],
            'message_id'  => payload[:direct_message_events].first[:id],
            'in_reply_to' => nil,
            'type_id'     => Ticket::Article::Type.find_by(name: 'twitter direct-message').id,
            'sender_id'   => Ticket::Article::Sender.find_by(name: 'Customer').id,
            'internal'    => false,
            'preferences' => { 'twitter' => twitter_prefs, 'links' => link_array }
          }
        end

        let(:twitter_prefs) do
          {
            'created_at'            => payload[:direct_message_events].first[:created_timestamp],
            'recipient_id'          => payload[:direct_message_events].first[:message_create][:target][:recipient_id],
            'recipient_screen_name' => payload[:users].values.second[:screen_name],
            'sender_id'             => payload[:direct_message_events].first[:message_create][:sender_id],
            'sender_screen_name'    => payload[:users].values.first[:screen_name],
            'app_id'                => payload[:apps]&.values&.first&.dig(:app_id),
            'app_name'              => payload[:apps]&.values&.first&.dig(:app_name),
            'geo'                   => {},
            'place'                 => {},
          }
        end

        let(:link_array) do
          [
            {
              'url'    => "https://twitter.com/messages/#{user_ids.map(&:to_i).sort.join('-')}",
              'target' => '_blank',
              'name'   => 'on Twitter',
            },
          ]
        end

        let(:user_ids) { payload[:users].values.map { |u| u[:id] } }

        it 'creates a new article' do
          expect { channel.process(payload) }
            .to change(Ticket::Article, :count).by(1)
            .and change { Ticket::Article.exists?(article_attributes) }.to(true)
        end

        context 'for duplicate messages' do
          before do
            channel.process(
              YAML.safe_load(File.read(payload_file), [ActiveSupport::HashWithIndifferentAccess])
            )
          end

          it 'does not create duplicate article' do
            expect { channel.process(payload) }
              .to not_change(Ticket::Article, :count)
          end
        end

        context 'when message contains shortened (t.co) url' do
          let(:payload_file) { Rails.root.join('test/data/twitter/webhook_events/direct_message-incoming_with_url.yml') }

          it 'replaces the t.co url for the original' do
            expect { channel.process(payload) }
              .to change { Ticket::Article.exists?(body: <<~BODY.chomp) }.to(true)
                Did you know about this? https://en.wikipedia.org/wiki/Frankenstein#Composition
              BODY
          end
        end
      end
    end

    context 'for outgoing DM' do
      let(:payload_file) { Rails.root.join('test/data/twitter/webhook_events/direct_message-outgoing.yml') }

      describe 'ticket creation' do
        let(:ticket_attributes) do
          # NOTE: missing "customer_id" (because User.last changes before and after the method is called)
          {
            'title'       => payload[:direct_message_events].first[:message_create][:message_data][:text],
            'group_id'    => channel.options[:sync][:direct_messages][:group_id],
            'state'       => Ticket::State.find_by(name: 'closed'),
            'priority'    => Ticket::Priority.find_by(default_create: true),
            'preferences' => {
              'channel_id'          => channel.id,
              'channel_screen_name' => channel.options[:user][:screen_name],
            },
          }
        end

        it 'creates a closed ticket' do
          expect { channel.process(payload) }
            .to change(Ticket, :count).by(1)
            .and change { Ticket.exists?(ticket_attributes) }.to(true)
        end
      end

      describe 'article creation' do
        let(:article_attributes) do
          # NOTE: missing "ticket_id" (because the value is generated as part of the #process method)
          {
            'from'        => "@#{payload[:users].values.first[:screen_name]}",
            'to'          => "@#{payload[:users].values.second[:screen_name]}",
            'body'        => payload[:direct_message_events].first[:message_create][:message_data][:text],
            'message_id'  => payload[:direct_message_events].first[:id],
            'in_reply_to' => nil,
            'type_id'     => Ticket::Article::Type.find_by(name: 'twitter direct-message').id,
            'sender_id'   => Ticket::Article::Sender.find_by(name: 'Customer').id,
            'internal'    => false,
            'preferences' => { 'twitter' => twitter_prefs, 'links' => link_array }
          }
        end

        let(:twitter_prefs) do
          {
            'created_at'            => payload[:direct_message_events].first[:created_timestamp],
            'recipient_id'          => payload[:direct_message_events].first[:message_create][:target][:recipient_id],
            'recipient_screen_name' => payload[:users].values.second[:screen_name],
            'sender_id'             => payload[:direct_message_events].first[:message_create][:sender_id],
            'sender_screen_name'    => payload[:users].values.first[:screen_name],
            'app_id'                => payload[:apps]&.values&.first&.dig(:app_id),
            'app_name'              => payload[:apps]&.values&.first&.dig(:app_name),
            'geo'                   => {},
            'place'                 => {},
          }
        end

        let(:link_array) do
          [
            {
              'url'    => "https://twitter.com/messages/#{user_ids.map(&:to_i).sort.join('-')}",
              'target' => '_blank',
              'name'   => 'on Twitter',
            },
          ]
        end

        let(:user_ids) { payload[:users].values.map { |u| u[:id] } }

        it 'creates a new article' do
          expect { channel.process(payload) }
            .to change(Ticket::Article, :count).by(1)
            .and change { Ticket::Article.exists?(article_attributes) }.to(true)
        end

        context 'when message contains shortened (t.co) url' do
          let(:payload_file) { Rails.root.join('test/data/twitter/webhook_events/direct_message-incoming_with_url.yml') }

          it 'replaces the t.co url for the original' do
            expect { channel.process(payload) }
              .to change { Ticket::Article.exists?(body: <<~BODY.chomp) }.to(true)
                Did you know about this? https://en.wikipedia.org/wiki/Frankenstein#Composition
              BODY
          end
        end

        context 'when message contains a media attachment (e.g., JPG)' do
          let(:payload_file) { Rails.root.join('test/data/twitter/webhook_events/direct_message-incoming_with_media.yml') }

          it 'does not store it as an attachment on the article' do
            channel.process(payload)

            expect(Ticket::Article.last.attachments).to be_empty
          end
        end
      end
    end

    context 'for incoming tweet' do
      let(:payload_file) { Rails.root.join('test/data/twitter/webhook_events/tweet_create-user_mention.yml') }

      include_examples 'for user processing' do
        # Payload sent by Twitter is { ..., tweet_create_events: [{ ..., user: <author> }] }
        let(:sender_profile) { payload[:tweet_create_events].first[:user] }
      end

      describe 'ticket creation' do
        let(:ticket_attributes) do
          # NOTE: missing "customer_id" (because User.last changes before and after the method is called)
          {
            'title'       => payload[:tweet_create_events].first[:text],
            'group_id'    => channel.options[:sync][:direct_messages][:group_id],
            'state'       => Ticket::State.find_by(default_create: true),
            'priority'    => Ticket::Priority.find_by(default_create: true),
            'preferences' => {
              'channel_id'          => channel.id,
              'channel_screen_name' => channel.options[:user][:screen_name],
            },
          }
        end

        it 'creates a new ticket' do
          expect { channel.process(payload) }
            .to change(Ticket, :count).by(1)
        end

        context 'for duplicate tweets' do
          before do
            channel.process(
              YAML.safe_load(File.read(payload_file), [ActiveSupport::HashWithIndifferentAccess])
            )
          end

          it 'does not create duplicate ticket' do
            expect { channel.process(payload) }
              .to not_change(Ticket, :count)
              .and not_change(Ticket::Article, :count)
          end
        end

        context 'in response to existing tweet thread' do
          let(:payload_file) { Rails.root.join('test/data/twitter/webhook_events/tweet_create-response.yml') }

          let(:parent_tweet_payload) do
            YAML.safe_load(
              File.read(Rails.root.join('test/data/twitter/webhook_events/tweet_create-user_mention.yml')),
              [ActiveSupport::HashWithIndifferentAccess]
            )
          end

          context 'that hasn’t been imported yet', :use_vcr do
            it 'creates a new ticket' do
              expect { channel.process(payload) }
                .to change(Ticket, :count).by(1)
            end

            it 'retrieves the parent tweet via the Twitter API' do
              expect { channel.process(payload) }
                .to change(Ticket::Article, :count).by(2)

              expect(Ticket::Article.second_to_last.body).to eq(parent_tweet_payload[:tweet_create_events].first[:text])
            end

            context 'after parent tweet has been deleted' do
              before do
                payload[:tweet_create_events].first[:in_reply_to_status_id] = 1207610954160037890 # rubocop:disable Style/NumericLiterals
                payload[:tweet_create_events].first[:in_reply_to_status_id_str] = '1207610954160037890'
              end

              it 'creates a new ticket' do
                expect { channel.process(payload) }
                  .to change(Ticket, :count).by(1)
              end

              it 'silently ignores error when retrieving parent tweet' do
                expect { channel.process(payload) }.to not_raise_error
              end
            end
          end

          context 'that was previously imported' do
            # import parent tweet
            before { channel.process(parent_tweet_payload) }

            it 'uses existing ticket' do
              expect { channel.process(payload) }
                .to not_change(Ticket, :count)
                .and not_change { Ticket.last.state }
            end

            context 'and marked "closed" / "merged" / "removed" / "pending reminder" / "pending close"' do
              before { Ticket.last.update(state: Ticket::State.find_by(name: 'closed')) }

              it 'sets existing ticket to "open"' do
                expect { channel.process(payload) }
                  .to not_change(Ticket, :count)
                  .and change { Ticket.last.state.name }.to('open')
              end
            end
          end
        end
      end

      describe 'article creation' do
        let(:article_attributes) do
          # NOTE: missing "ticket_id" (because the value is generated as part of the #process method)
          {
            'from'        => "@#{payload[:tweet_create_events].first[:user][:screen_name]}",
            'to'          => "@#{payload[:tweet_create_events].first[:entities][:user_mentions].first[:screen_name]}",
            'body'        => payload[:tweet_create_events].first[:text],
            'message_id'  => payload[:tweet_create_events].first[:id_str],
            'in_reply_to' => payload[:tweet_create_events].first[:in_reply_to_status_id],
            'type_id'     => Ticket::Article::Type.find_by(name: 'twitter status').id,
            'sender_id'   => Ticket::Article::Sender.find_by(name: 'Customer').id,
            'internal'    => false,
            'preferences' => { 'twitter' => twitter_prefs, 'links' => link_array }
          }
        end

        let(:twitter_prefs) do
          {
            'mention_ids'         => payload[:tweet_create_events].first[:entities][:user_mentions].map { |um| um[:id] },
            'geo'                 => payload[:tweet_create_events].first[:geo].to_h,
            'retweeted'           => payload[:tweet_create_events].first[:retweeted],
            'possibly_sensitive'  => payload[:tweet_create_events].first[:possibly_sensitive],
            'in_reply_to_user_id' => payload[:tweet_create_events].first[:in_reply_to_user_id],
            'place'               => payload[:tweet_create_events].first[:place].to_h,
            'retweet_count'       => payload[:tweet_create_events].first[:retweet_count],
            'source'              => payload[:tweet_create_events].first[:source],
            'favorited'           => payload[:tweet_create_events].first[:favorited],
            'truncated'           => payload[:tweet_create_events].first[:truncated],
          }
        end

        let(:link_array) do
          [
            {
              'url'    => "https://twitter.com/_/status/#{payload[:tweet_create_events].first[:id]}",
              'target' => '_blank',
              'name'   => 'on Twitter',
            },
          ]
        end

        it 'creates a new article' do
          expect { channel.process(payload) }
            .to change(Ticket::Article, :count).by(1)
            .and change { Ticket::Article.exists?(article_attributes) }.to(true)
        end

        context 'when message mentions multiple users' do
          let(:payload_file) { Rails.root.join('test/data/twitter/webhook_events/tweet_create-user_mention_multiple.yml') }

          let(:mentionees) { "@#{payload[:tweet_create_events].first[:entities][:user_mentions].map { |um| um[:screen_name] }.join(', @')}" }

          it 'records all mentionees in comma-separated "to" attribute' do
            expect { channel.process(payload) }
              .to change { Ticket::Article.exists?(to: mentionees) }.to(true)
          end
        end

        context 'when message exceeds 140 characters' do
          let(:payload_file) { Rails.root.join('test/data/twitter/webhook_events/tweet_create-user_mention_extended.yml') }

          let(:full_body) { payload[:tweet_create_events].first[:extended_tweet][:full_text] }

          it 'records the full (extended) tweet body' do
            expect { channel.process(payload) }
              .to change { Ticket::Article.exists?(body: full_body) }.to(true)
          end
        end

        context 'when message contains shortened (t.co) url' do
          let(:payload_file) { Rails.root.join('test/data/twitter/webhook_events/tweet_create-user_mention_with_url.yml') }

          it 'replaces the t.co url for the original' do
            expect { channel.process(payload) }
              .to change { Ticket::Article.exists?(body: <<~BODY.chomp) }.to(true)
                @ScruffyMcG https://zammad.org/
              BODY
          end
        end

        context 'when message contains a media attachment (e.g., JPG)' do
          let(:payload_file) { Rails.root.join('test/data/twitter/webhook_events/tweet_create-user_mention_with_media.yml') }

          it 'replaces the t.co url for the original' do
            expect { channel.process(payload) }
              .to change { Ticket::Article.exists?(body: <<~BODY.chomp) }.to(true)
                @ScruffyMcG https://twitter.com/pennbrooke1/status/1209101446706122752/photo/1
              BODY
          end

          it 'stores it as an attachment on the article', :use_vcr do
            channel.process(payload)

            expect(Ticket::Article.last.attachments).to be_one
          end
        end
      end
    end

    context 'for outgoing tweet' do
      let(:payload_file) { Rails.root.join('test/data/twitter/webhook_events/tweet_create-user_mention_outgoing.yml') }

      describe 'ticket creation' do
        let(:ticket_attributes) do
          # NOTE: missing "customer_id" (because User.last changes before and after the method is called)
          {
            'title'       => payload[:tweet_create_events].first[:text],
            'group_id'    => channel.options[:sync][:direct_messages][:group_id],
            'state'       => Ticket::State.find_by(name: 'closed'),
            'priority'    => Ticket::Priority.find_by(default_create: true),
            'preferences' => {
              'channel_id'          => channel.id,
              'channel_screen_name' => channel.options[:user][:screen_name],
            },
          }
        end

        it 'creates a closed ticket' do
          expect { channel.process(payload) }
            .to change(Ticket, :count).by(1)
        end
      end

      describe 'article creation' do
        let(:article_attributes) do
          # NOTE: missing "ticket_id" (because the value is generated as part of the #process method)
          {
            'from'        => "@#{payload[:tweet_create_events].first[:user][:screen_name]}",
            'to'          => "@#{payload[:tweet_create_events].first[:entities][:user_mentions].first[:screen_name]}",
            'body'        => payload[:tweet_create_events].first[:text],
            'message_id'  => payload[:tweet_create_events].first[:id_str],
            'in_reply_to' => payload[:tweet_create_events].first[:in_reply_to_status_id],
            'type_id'     => Ticket::Article::Type.find_by(name: 'twitter status').id,
            'sender_id'   => Ticket::Article::Sender.find_by(name: 'Customer').id,
            'internal'    => false,
            'preferences' => { 'twitter' => twitter_prefs, 'links' => link_array }
          }
        end

        let(:twitter_prefs) do
          {
            'mention_ids'         => payload[:tweet_create_events].first[:entities][:user_mentions].map { |um| um[:id] },
            'geo'                 => payload[:tweet_create_events].first[:geo].to_h,
            'retweeted'           => payload[:tweet_create_events].first[:retweeted],
            'possibly_sensitive'  => payload[:tweet_create_events].first[:possibly_sensitive],
            'in_reply_to_user_id' => payload[:tweet_create_events].first[:in_reply_to_user_id],
            'place'               => payload[:tweet_create_events].first[:place].to_h,
            'retweet_count'       => payload[:tweet_create_events].first[:retweet_count],
            'source'              => payload[:tweet_create_events].first[:source],
            'favorited'           => payload[:tweet_create_events].first[:favorited],
            'truncated'           => payload[:tweet_create_events].first[:truncated],
          }
        end

        let(:link_array) do
          [
            {
              'url'    => "https://twitter.com/_/status/#{payload[:tweet_create_events].first[:id]}",
              'target' => '_blank',
              'name'   => 'on Twitter',
            },
          ]
        end

        it 'creates a new article' do
          expect { channel.process(payload) }
            .to change(Ticket::Article, :count).by(1)
            .and change { Ticket::Article.exists?(article_attributes) }.to(true)
        end
      end
    end
  end
end
