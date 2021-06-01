# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CommunicateTwitterJob, type: :job do

  let(:article) { create(:twitter_article, **(try(:factory_options) || {})) }

  describe 'core behavior', :use_vcr do

    context 'for tweets' do
      let(:tweet_attributes) do
        {
          'mention_ids'         => [],
          'geo'                 => {},
          'retweeted'           => false,
          'possibly_sensitive'  => false,
          'in_reply_to_user_id' => nil,
          'place'               => {},
          'retweet_count'       => 0,
          'source'              => '<a href="https://zammad.com/" rel="nofollow">zammad</a>',
          'favorited'           => false,
          'truncated'           => false,
        }
      end

      let(:links_array) do
        [{
          url:    'https://twitter.com/_/status/1244937367435108360',
          target: '_blank',
          name:   'on Twitter',
        }]
      end

      it 'increments the "delivery_retry" preference' do
        expect { described_class.perform_now(article.id) }
          .to change { article.reload.preferences[:delivery_retry] }.to(1)
      end

      it 'dispatches the tweet' do
        described_class.perform_now(article.id)

        expect(WebMock)
          .to have_requested(:post, 'https://api.twitter.com/1.1/statuses/update.json')
          .with(body: "in_reply_to_status_id&status=#{CGI.escape(article.body)}" )
      end

      it 'updates the article with tweet attributes' do
        expect { described_class.perform_now(article.id) }
          .to change { article.reload.message_id }.to('1244937367435108360')
          .and change { article.reload.preferences[:twitter] }.to(hash_including(tweet_attributes))
          .and change { article.reload.preferences[:links] }.to(links_array)
      end

      it 'sets the appropriate delivery status attributes' do
        expect { described_class.perform_now(article.id) }
          .to change { article.reload.preferences[:delivery_status] }.to('success')
          .and change { article.reload.preferences[:delivery_status_date] }.to(an_instance_of(ActiveSupport::TimeWithZone))
          .and not_change { article.reload.preferences[:delivery_status_message] }.from(nil)
      end

      context 'with a user mention' do
        let(:factory_options) { { body: '@twitter @twitterlive Don’t mind me, just testing the API' } }

        it 'updates the article with tweet recipients' do
          expect { described_class.perform_now(article.id) }
            .to change { article.reload.to }.to('@Twitter @TwitterLive')
        end
      end
    end

    context 'for DMs' do
      let(:article) { create(:twitter_dm_article, :pending_delivery, recipient: recipient, body: 'Please ignore this message.') }
      let(:recipient) { create(:twitter_authorization, uid: '2688148651', username: 'AirbnbHelp') }

      let(:request_body) do
        {
          event: {
            type:           'message_create',
            message_create: {
              target:       { recipient_id: recipient.uid },
              message_data: { text: article.body }
            }
          }
        }.to_json
      end

      let(:dm_attributes) do
        {
          'recipient_id' => recipient.uid,
          'sender_id'    => '1205290247124217856',
        }
      end

      let(:links_array) do
        [{
          url:    "https://twitter.com/messages/#{recipient.uid}-1205290247124217856",
          target: '_blank',
          name:   'on Twitter',
        }]
      end

      it 'increments the "delivery_retry" preference' do
        expect { described_class.perform_now(article.id) }
          .to change { article.reload.preferences[:delivery_retry] }.to(1)
      end

      it 'dispatches the DM' do
        described_class.perform_now(article.id)

        expect(WebMock)
          .to have_requested(:post, 'https://api.twitter.com/1.1/direct_messages/events/new.json')
          .with(body: request_body)
      end

      it 'updates the article with DM attributes' do
        expect { described_class.perform_now(article.id) }
          .to change { article.reload.message_id }.to('1244953398509617156')
          .and change { article.reload.preferences[:twitter] }.to(hash_including(dm_attributes))
          .and change { article.reload.preferences[:links] }.to(links_array)
      end

      it 'sets the appropriate delivery status attributes' do
        expect { described_class.perform_now(article.id) }
          .to change { article.reload.preferences[:delivery_status] }.to('success')
          .and change { article.reload.preferences[:delivery_status_date] }.to(an_instance_of(ActiveSupport::TimeWithZone))
          .and not_change { article.reload.preferences[:delivery_status_message] }.from(nil)
      end
    end

    describe 'failure cases' do
      shared_examples 'for failure cases' do
        it 'raises an error and sets the appropriate delivery status messages' do
          expect { described_class.perform_now(article.id) }
            .to change { article.reload.preferences[:delivery_status] }.to('fail')
            .and change { article.reload.preferences[:delivery_status_date] }.to(an_instance_of(ActiveSupport::TimeWithZone))
            .and change { article.reload.preferences[:delivery_status_message] }.to(error_message)
        end
      end

      context 'when article.ticket.preferences["channel_id"] is nil' do
        before do
          article.ticket.preferences.delete(:channel_id)
          article.ticket.save
        end

        let(:error_message) { "Can't find ticket.preferences['channel_id'] for Ticket.find(#{article.ticket_id})" }

        include_examples 'for failure cases'
      end

      context 'if article.ticket.preferences["channel_id"] has been removed' do
        before { channel.destroy }

        let(:channel) { Channel.find(article.ticket.preferences[:channel_id]) }
        let(:error_message) { "No such channel id #{article.ticket.preferences['channel_id']}" }

        include_examples 'for failure cases'

        context 'and another suitable channel exists (matching on ticket.preferences[:channel_screen_name])' do
          let!(:new_channel) { create(:twitter_channel, custom_options: { user: { screen_name: channel.options[:user][:screen_name] } }) }

          it 'uses that channel' do
            described_class.perform_now(article.id)

            expect(WebMock)
              .to have_requested(:post, 'https://api.twitter.com/1.1/statuses/update.json')
              .with(body: "in_reply_to_status_id&status=#{CGI.escape(article.body)}" )
          end
        end
      end

      context 'if article.ticket.preferences["channel_id"] isn’t actually a twitter channel' do
        before do
          article.ticket.preferences[:channel_id] = create(:email_channel).id
          article.ticket.save
        end

        let(:error_message) { "Channel.find(#{article.ticket.preferences[:channel_id]}) isn't a twitter channel!" }

        include_examples 'for failure cases'
      end

      context 'when tweet dispatch fails (e.g., due to authentication error)' do
        before do
          article.ticket.preferences[:channel_id] = create(:twitter_channel, :invalid).id
          article.ticket.save
        end

        let(:error_message) { "Can't use Channel::Driver::Twitter: #<Twitter::Error::Unauthorized: Invalid or expired token.>" }

        include_examples 'for failure cases'
      end

      context 'when tweet comes back nil' do
        before do
          allow(Twitter::REST::Client).to receive(:new).with(any_args).and_return(client_double)
          allow(client_double).to receive(:update).with(any_args).and_return(nil)
        end

        let(:client_double) { double('Twitter::REST::Client') }
        let(:error_message) { 'Got no tweet!' }

        include_examples 'for failure cases'
      end

      context 'on the fourth time it fails' do
        before { Channel.find(article.ticket.preferences[:channel_id]).destroy }

        let(:error_message) { "No such channel id #{article.ticket.preferences['channel_id']}" }
        let(:factory_options) { { preferences: { delivery_retry: 3 } } }

        it 'adds a delivery failure note (article) to the ticket' do
          expect { described_class.perform_now(article.id) }
            .to change { article.ticket.reload.articles.count }.by(1)

          expect(Ticket::Article.last.attributes).to include(
            'content_type' => 'text/plain',
            'body'         => "Unable to send tweet: #{error_message}",
            'internal'     => true,
            'sender_id'    => Ticket::Article::Sender.find_by(name: 'System').id,
            'type_id'      => Ticket::Article::Type.find_by(name: 'note').id,
            'preferences'  => {
              'delivery_article_id_related' => article.id,
              'delivery_message'            => true,
            },
          )
        end
      end
    end
  end
end
