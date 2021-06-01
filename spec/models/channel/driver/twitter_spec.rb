# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Driver::Twitter do
  subject(:channel) { create(:twitter_channel) }

  let(:external_credential) { ExternalCredential.find(channel.options[:auth][:external_credential_id]) }

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

        let(:user_ids) { payload[:users].values.pluck(:id) }

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

        let(:user_ids) { payload[:users].values.pluck(:id) }

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
            'mention_ids'         => payload[:tweet_create_events].first[:entities][:user_mentions].pluck(:id),
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

          let(:mentionees) { "@#{payload[:tweet_create_events].first[:entities][:user_mentions].pluck(:screen_name).join(', @')}" }

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

        context 'when message is a retweet' do
          let(:payload_file) { Rails.root.join('test/data/twitter/webhook_events/tweet_create-retweet.yml') }

          context 'and "conversion of retweets" is enabled' do
            before do
              channel.options['sync']['track_retweets'] = true
              channel.save
            end

            it 'creates a new article' do
              expect { channel.process(payload) }
                .to change(Ticket::Article, :count).by(1)
                .and change { Ticket::Article.exists?(article_attributes) }.to(true)
            end
          end

          context 'and "conversion of retweets" is disabled' do
            before do
              channel.options['sync']['track_retweets'] = false
              channel.save
            end

            it 'does not create a new article' do
              expect { channel.process(payload) }
                .not_to change(Ticket::Article, :count)
            end
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
            'mention_ids'         => payload[:tweet_create_events].first[:entities][:user_mentions].pluck(:id),
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

  describe '#send', :use_vcr do
    shared_examples 'for #send' do
      # Channel#deliver takes a hash in the following format
      # (see CommunicateTwitterJob#perform)
      #
      # Why not just accept the whole article?
      # Presumably so all channels have a consistent interface...
      # but it might be a good idea to let it accept both one day
      # (the "robustness principle")
      let(:delivery_payload) do
        {
          type:        outgoing_tweet.type.name,
          to:          outgoing_tweet.to,
          body:        outgoing_tweet.body,
          in_reply_to: outgoing_tweet.in_reply_to
        }
      end

      describe 'Import Mode behavior' do
        before { Setting.set('import_mode', true) }

        it 'is a no-op' do
          expect(Twitter::REST::Client).not_to receive(:new)

          channel.deliver(delivery_payload)
        end
      end

      describe 'Twitter API authentication' do
        let(:consumer_credentials) do
          {
            consumer_key:    external_credential.credentials[:consumer_key],
            consumer_secret: external_credential.credentials[:consumer_secret],
          }
        end

        let(:oauth_credentials) do
          {
            access_token:        channel.options[:auth][:oauth_token],
            access_token_secret: channel.options[:auth][:oauth_token_secret],
          }
        end

        it 'uses consumer key/secret stored on ExternalCredential' do
          expect(Twitter::REST::Client)
            .to receive(:new).with(hash_including(consumer_credentials))
            .and_call_original

          channel.deliver(delivery_payload)
        end

        it 'uses OAuth token/secret stored on #options hash' do
          expect(Twitter::REST::Client)
            .to receive(:new).with(hash_including(oauth_credentials))
            .and_call_original

          channel.deliver(delivery_payload)
        end
      end

      describe 'Twitter API activity' do
        it 'creates a tweet/DM via the API' do
          channel.deliver(delivery_payload)

          expect(WebMock)
            .to have_requested(:post, "https://api.twitter.com/1.1#{endpoint}")
            .with(body: request_body)
        end

        it 'returns the created tweet/DM' do
          expect(channel.deliver(delivery_payload)).to match(return_value)
        end
      end
    end

    context 'for tweets' do
      let!(:outgoing_tweet) { create(:twitter_article) }
      let(:endpoint) { '/statuses/update.json' }
      let(:request_body) { <<~BODY.chomp }
        in_reply_to_status_id&status=#{URI.encode_www_form_component(outgoing_tweet.body)}
      BODY
      let(:return_value) { Twitter::Tweet }

      include_examples 'for #send'

      context 'in a thread' do
        let!(:outgoing_tweet) { create(:twitter_article, :reply) }
        let(:request_body) { <<~BODY.chomp }
          in_reply_to_status_id=#{outgoing_tweet.in_reply_to}&status=#{URI.encode_www_form_component(outgoing_tweet.body)}
        BODY

        it 'creates a tweet via the API' do
          channel.deliver(delivery_payload)

          expect(WebMock)
            .to have_requested(:post, "https://api.twitter.com/1.1#{endpoint}")
            .with(body: request_body)
        end
      end

      context 'containing an asterisk (workaround for sferik/twitter #677)' do
        let!(:outgoing_tweet) { create(:twitter_article, body: 'foo * bar') }
        let(:request_body) { <<~BODY.chomp }
          in_reply_to_status_id&status=#{URI.encode_www_form_component('foo ＊ bar')}
        BODY

        it 'converts it to a full-width asterisk (U+FF0A)' do
          channel.deliver(delivery_payload)

          expect(WebMock)
            .to have_requested(:post, "https://api.twitter.com/1.1#{endpoint}")
            .with(body: request_body)
        end
      end
    end

    context 'for DMs' do
      let!(:outgoing_tweet) { create(:twitter_dm_article, :pending_delivery) }
      let(:endpoint) { '/direct_messages/events/new.json' }
      let(:request_body) { <<~BODY.chomp }
        {"event":{"type":"message_create","message_create":{"target":{"recipient_id":"#{Authorization.last.uid}"},"message_data":{"text":"#{outgoing_tweet.body}"}}}}
      BODY
      let(:return_value) { { event: hash_including(type: 'message_create') } }

      include_examples 'for #send'
    end
  end

  describe '#fetch', use_vcr: :time_sensitive do
    describe 'rate limiting' do
      before do
        allow(Rails.env).to receive(:test?).and_return(false)
        channel.fetch
      end

      context 'within 20 minutes of last run' do
        before { travel(19.minutes) }

        it 'aborts' do
          expect { channel.fetch }
            .not_to change { channel.reload.preferences[:last_fetch] }
        end
      end

      context '20+ minutes since last run' do
        before { travel(20.minutes) }

        it 'runs again' do
          expect { channel.fetch }
            .to change { channel.reload.preferences[:last_fetch] }
        end
      end
    end

    describe 'Twitter API authentication' do
      let(:consumer_credentials) do
        {
          consumer_key:    external_credential.credentials[:consumer_key],
          consumer_secret: external_credential.credentials[:consumer_secret],
        }
      end

      let(:oauth_credentials) do
        {
          access_token:        channel.options[:auth][:oauth_token],
          access_token_secret: channel.options[:auth][:oauth_token_secret],
        }
      end

      it 'uses consumer key/secret stored on ExternalCredential' do
        expect(Twitter::REST::Client)
          .to receive(:new).with(hash_including(consumer_credentials))
          .and_call_original

        channel.fetch
      end

      it 'uses OAuth token/secret stored on #options hash' do
        expect(Twitter::REST::Client)
          .to receive(:new).with(hash_including(oauth_credentials))
          .and_call_original

        channel.fetch
      end
    end

    describe 'Twitter API activity' do
      it 'sets successful status attributes' do
        expect { channel.fetch }
          .to change { channel.reload.attributes }
          .to hash_including(
            'status_in'    => 'ok',
            'last_log_in'  => '',
            'status_out'   => nil,
            'last_log_out' => nil
          )
      end

      context 'with search term configured (at .options[:sync][:search])' do
        it 'creates an article for each recent tweet' do
          expect { channel.fetch }
            .to change(Ticket, :count).by(2)

          expect(Ticket.last.attributes).to include(
            'title'       => "Come and join our team to bring Zammad even further forward!   It's gonna be ama...",
            'preferences' => { 'channel_id'          => channel.id,
                               'channel_screen_name' => channel.options[:user][:screen_name] },
            'customer_id' => User.find_by(firstname: 'Mr.Generation', lastname: '').id
          )
        end

        context 'for responses to other tweets' do
          let(:thread) do
            Ticket.joins(articles: :type).where(ticket_article_types: { name: 'twitter status' })
              .group('tickets.id').having(
                case ActiveRecord::Base.connection_config[:adapter]
                when 'mysql2'
                  'COUNT("ticket_articles.*") > 1'
                when 'postgresql'
                  'COUNT(ticket_articles.*) > 1'
                end
              ).first
          end

          it 'creates articles for parent tweets as well' do
            channel.fetch

            expect(thread.articles.last.body).to match(%r{zammad}i)       # search result
            expect(thread.articles.first.body).not_to match(%r{zammad}i)  # parent tweet
          end
        end

        context 'and "track_retweets" option' do
          context 'is false (default)' do
            it 'skips retweets' do
              expect { channel.fetch }
                .not_to change { Ticket.where('title LIKE ?', 'RT @%').count }.from(0)
            end
          end

          context 'is true' do
            subject(:channel) { create(:twitter_channel, custom_options: { sync: { track_retweets: true } }) }

            it 'creates an article for each recent tweet/retweet' do
              expect { channel.fetch }
                .to change { Ticket.where('title LIKE ?', 'RT @%').count }.by(1)
                .and change(Ticket, :count).by(3)
            end
          end
        end

        context 'and "import_older_tweets" option (legacy)' do
          context 'is false (default)' do
            it 'skips tweets 15+ days older than channel itself' do
              expect { channel.fetch }
                .not_to change { Ticket.where('title LIKE ?', 'GitHub Trending Archive, 29 Nov 2018, Ruby. %').count }.from(0)
            end
          end

          context 'is true' do
            subject(:channel) { create(:twitter_channel, :legacy) }

            it 'creates an article for each tweet' do
              expect { channel.fetch }
                .to change { Ticket.where('title LIKE ?', 'GitHub Trending Archive, 29 Nov 2018, Ruby. %').count }.by(1)
                .and change(Ticket, :count).by(3)
            end
          end
        end

        describe 'duplicate handling' do
          context 'when fetched tweets have already been imported' do
            before do
              tweet_ids.each { |tweet_id| create(:ticket_article, message_id: tweet_id) }
            end

            let(:tweet_ids) { [1222126386334388225, 1222109934923460608] } # rubocop:disable Style/NumericLiterals

            it 'does not import duplicates' do
              expect { channel.fetch }.not_to change(Ticket::Article, :count)
            end
          end

          describe 'Race condition: when #fetch finds a half-processed, outgoing tweet' do
            subject!(:channel) do
              create(:twitter_channel,
                     search_term:    'zammadzammadzammad',
                     custom_options: {
                       user: {
                         # "outgoing" tweets = authored by this Twitter user ID
                         id: '1205290247124217856',
                       },
                     })
            end

            # This test case requires the use_vcr: :time_sensitive option
            # to travel_to(when the VCR cassette was recorded).
            #
            # This ensures that #fetch doesn't ignore
            # the "older" tweets stored in the VCR cassette,
            # but it also freezes time,
            # which breaks this test expectation logic:
            #
            #     expect { channel.fetch }.to change(Time, :current).by_at_least(5)
            #
            # So, we unfreeze time here.
            before { travel_back }

            let!(:tweet) { create(:twitter_article, body: 'zammadzammadzammad') }

            context '(i.e., after the BG job has posted the article to Twitter…' do
              # NOTE: This context block cannot be set up programmatically.
              # Instead, the tweet was posted, fetched, recorded into a VCR cassette,
              # and then manually copied into the existing VCR cassette for this example.

              context '…but before the BG job has "synced" article.message_id with tweet.id)' do
                let(:twitter_job) { Delayed::Job.where("handler LIKE '%job_class: CommunicateTwitterJob%#{tweet.id}%'").first }

                around do |example|
                  # Run BG job (Why not use Scheduler.worker?
                  # It led to hangs & failures elsewhere in test suite.)
                  Thread.new do
                    sleep 5 # simulate other bg jobs holding up the queue
                    twitter_job.invoke_job
                  end.tap { example.run }.join
                end

                it 'does not import the duplicate tweet (waits up to 60s for BG job to finish)' do
                  expect { channel.fetch }
                    .to not_change(Ticket::Article, :count)
                    .and change(Time, :current).by_at_least(5)
                end
              end
            end

            # To reproduce this test case, the VCR cassette has been modified
            # so that the fetched tweet has a different ("incoming") author user ID.
            it 'skips race condition handling for incoming tweets' do
              expect { channel.fetch }
                .to change(Ticket::Article, :count)
                .and change(Time, :current).by_at_most(1)
            end
          end
        end

        context 'for very common search terms' do
          subject(:channel) { create(:twitter_channel, search_term: 'coronavirus') }

          let(:twitter_articles) { Ticket::Article.joins(:type).where(ticket_article_types: { name: 'twitter status' }) }

          # NOTE: Ordinarily, RSpec examples should be kept as small as possible.
          # In this case, we bundle these examples together because
          # separating them would duplicate expensive setup:
          # even with HTTP caching, this single example takes nearly a minute.
          #
          # Also, note that this rate limiting is partially duplicated
          # in #fetchable?, which prevents #fetch from running
          # more than once in a 20-minute period.
          it 'imports max. ~120 articles every 15 minutes' do
            channel.fetch

            expect((twitter_articles - Ticket.last.articles).count).to be <= 120
            expect(twitter_articles.count).to be > 120

            travel(14.minutes)

            expect { create(:twitter_channel).fetch }
              .not_to change(Ticket::Article, :count)

            travel(1.minute)

            expect { create(:twitter_channel).fetch }
              .to change(Ticket::Article, :count)
          end
        end
      end
    end
  end
end
