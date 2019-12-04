require 'rails_helper'

RSpec.describe 'Twitter Webhook Integration', type: :request do
  let!(:external_credential) { create(:twitter_credential, credentials: credentials) }
  let(:credentials) { { consumer_key: 'CCC', consumer_secret: 'DDD' } }

  describe '#webhook_incoming' do
    let!(:channel) do
      create(
        :twitter_channel,
        custom_options: {
          auth: {
            external_credential_id: external_credential.id,
            oauth_token:            'AAA',
            oauth_token_secret:     'BBB',
            consumer_key:           'CCC',
            consumer_secret:        'DDD',
          },
          user: {
            id:          123,
            name:        'Zammad HQ',
            screen_name: 'zammadhq',
          },
          sync: {
            limit:          20,
            track_retweets: false,
            search:         [
              {
                term: '#zammad', group_id: Group.first.id.to_s
              },
              {
                term: '#hello1234', group_id: Group.first.id.to_s
              }
            ],
          }
        }
      )
    end

    describe 'auto-creation of tickets/articles on webhook receipt' do
      let(:webhook_payload) do
        JSON.parse(File.read(Rails.root.join('test/data/twitter', payload_file))).symbolize_keys
      end

      context 'for outbound DMs' do
        context 'not matching any admin-defined filters' do
          let(:payload_file) { 'webhook1_direct_message.json' }

          it 'returns 200' do
            post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json

            expect(response).to have_http_status(:ok)
          end

          it 'creates closed ticket' do
            expect { post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json }
              .to change(Ticket, :count).by(1)

            expect(Ticket.last.attributes)
              .to include(
                'title'         => 'Hey! Hello!',
                'state_id'      => Ticket::State.find_by(name: 'closed').id,
                'priority_id'   => Ticket::Priority.find_by(name: '2 normal').id,
                'customer_id'   => User.find_by(login: 'zammadhq', firstname: 'Zammad', lastname: 'Hq').id,
                'created_by_id' => User.find_by(login: 'zammadhq', firstname: 'Zammad', lastname: 'Hq').id
              )
          end

          it 'creates first article on closed ticket' do
            expect { post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json }
              .to change { Ticket::Article.count }.by(1)

            expect(Ticket::Article.last.attributes)
              .to include(
                'from'          => '@zammadhq',
                'to'            => '@medenhofer',
                'message_id'    => '1062015437679050760',
                'created_by_id' => User.find_by(login: 'zammadhq', firstname: 'Zammad', lastname: 'Hq').id
              )
          end

          it 'does not add any attachments to newly created ticket' do
            post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json

            expect(Ticket::Article.last.attachments).to be_empty
          end
        end
      end

      context 'for inbound DMs' do
        context 'matching admin-defined #hashtag filter, with a link to an image' do
          let(:payload_file) { 'webhook2_direct_message.json' }

          it 'returns 200' do
            post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json

            expect(response).to have_http_status(:ok)
          end

          it 'creates new ticket' do
            expect { post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json }
              .to change(Ticket, :count).by(1)

            expect(Ticket.last.attributes)
              .to include(
                'title'       => 'Hello Zammad #zammad @znuny  Yeah! https://t.co/UfaCwi9cUb',
                'state_id'    => Ticket::State.find_by(name: 'new').id,
                'priority_id' => Ticket::Priority.find_by(name: '2 normal').id,
                'customer_id' => User.find_by(login: 'medenhofer', firstname: 'Martin', lastname: 'Edenhofer').id,
              )
          end

          it 'creates first article on new ticket' do
            expect { post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json }
              .to change { Ticket::Article.count }.by(1)

            expect(Ticket::Article.last.attributes)
              .to include(
                'to'            => '@zammadhq',
                'from'          => '@medenhofer',
                'body'          => "Hello Zammad #zammad @znuny\n\nYeah! https://twitter.com/messages/media/1063077238797725700",
                'message_id'    => '1063077238797725700',
                'created_by_id' => User.find_by(login: 'medenhofer', firstname: 'Martin', lastname: 'Edenhofer').id
              )
          end

          it 'does not add linked image as attachment to newly created ticket' do
            post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json

            expect(Ticket::Article.last.attachments).to be_empty
          end
        end

        context 'from same sender as previously imported DMs' do
          let(:payload_file) { 'webhook3_direct_message.json' }

          before { post '/api/v1/channels_twitter_webhook', **previous_webhook_payload, as: :json }

          let(:previous_webhook_payload) do
            JSON.parse(File.read(Rails.root.join('test/data/twitter/webhook2_direct_message.json'))).symbolize_keys
          end

          it 'returns 200' do
            post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json

            expect(response).to have_http_status(:ok)
          end

          it 'does not create new ticket' do
            expect { post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json }
              .not_to change(Ticket, :count)
          end

          it 'adds new article to existing, open ticket' do
            expect { post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json }
              .to change { Ticket::Article.count }.by(1)

            expect(Ticket::Article.last.attributes)
              .to include(
                'to'            => '@zammadhq',
                'from'          => '@medenhofer',
                'body'          => 'Hello again!',
                'message_id'    => '1063077238797725701',
                'created_by_id' => User.find_by(login: 'medenhofer', firstname: 'Martin', lastname: 'Edenhofer').id,
                'ticket_id'     => Ticket.find_by(title: 'Hello Zammad #zammad @znuny  Yeah! https://t.co/UfaCwi9cUb').id
              )
          end

          it 'does not add any attachments to newly created ticket' do
            post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json

            expect(Ticket::Article.last.attachments).to be_empty
          end
        end
      end

      context 'when receiving duplicate DMs' do
        let(:payload_file) { 'webhook1_direct_message.json' }

        it 'still returns 200' do
          2.times { post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json }

          expect(response).to have_http_status(:ok)
        end

        it 'does not create duplicate articles' do
          expect do
            2.times { post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json }
          end.to change { Ticket::Article.count }.by(1)
        end
      end

      context 'for tweets' do
        context 'matching admin-defined #hashtag filter, with an image link' do
          let(:payload_file) { 'webhook1_tweet.json' }

          before do
            stub_request(:get, 'http://pbs.twimg.com/profile_images/785412960797745152/wxdIvejo_bigger.jpg')
              .to_return(status: 200, body: 'some_content')

            stub_request(:get, 'https://pbs.twimg.com/media/DsFKfJRWkAAFEbo.jpg')
              .to_return(status: 200, body: 'some_content')
          end

          it 'returns 200' do
            post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json

            expect(response).to have_http_status(:ok)
          end

          it 'creates a closed ticket' do
            expect { post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json }
              .to change(Ticket, :count).by(1)

            expect(Ticket.last.attributes)
              .to include(
                'title'         => 'Hey @medenhofer !  #hello1234 https://t.co/f1kffFlwpN',
                'state_id'      => Ticket::State.find_by(name: 'closed').id,
                'priority_id'   => Ticket::Priority.find_by(name: '2 normal').id,
                'customer_id'   => User.find_by(login: 'zammadhq', firstname: 'Zammad', lastname: 'Hq').id,
                'created_by_id' => User.find_by(login: 'zammadhq', firstname: 'Zammad', lastname: 'Hq').id,
              )
          end

          it 'creates first article on closed ticket' do
            expect { post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json }
              .to change { Ticket::Article.count }.by(1)

            expect(Ticket::Article.last.attributes)
              .to include(
                'from'          => '@zammadhq',
                'to'            => '@medenhofer',
                'body'          => 'Hey @medenhofer !  #hello1234 https://twitter.com/zammadhq/status/1063212927510081536/photo/1',
                'message_id'    => '1063212927510081536',
                'created_by_id' => User.find_by(login: 'zammadhq', firstname: 'Zammad', lastname: 'Hq').id
              )
          end

          it 'add linked image as attachment to newly created article' do
            expect(Ticket::Article.last.attachments)
              .to match_array(Store.where(filename: 'DsFKfJRWkAAFEbo.jpg'))
          end
        end

        context 'longer than 140 characters (with no media links)' do
          let(:payload_file) { 'webhook2_tweet.json' }

          before do
            stub_request(:get, 'http://pbs.twimg.com/profile_images/794220000450150401/D-eFg44R_bigger.jpg')
              .to_return(status: 200, body: 'some_content')
          end

          it 'returns 200' do
            post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json

            expect(response).to have_http_status(:ok)
          end

          it 'creates a new ticket' do
            expect { post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json }
              .to change(Ticket, :count).by(1)

            expect(Ticket.last.attributes)
              .to include(
                'title'         => '@znuny Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy ...',
                'state_id'      => Ticket::State.find_by(name: 'new').id,
                'priority_id'   => Ticket::Priority.find_by(name: '2 normal').id,
                'customer_id'   => User.find_by(login: 'medenhofer', firstname: 'Martin', lastname: 'Edenhofer').id,
                'created_by_id' => User.find_by(login: 'medenhofer', firstname: 'Martin', lastname: 'Edenhofer').id,
              )
          end

          it 'creates first article on new ticket' do
            expect { post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json }
              .to change { Ticket::Article.count }.by(1)

            expect(Ticket::Article.last.attributes)
              .to include(
                'from'          => '@medenhofer',
                'to'            => '@znuny',
                'body'          => '@znuny Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lore',
                'created_by_id' => User.find_by(login: 'medenhofer', firstname: 'Martin', lastname: 'Edenhofer').id,
                'message_id'    => '1065035365336141825'
              )
          end

          it 'does not add any attachments to newly created ticket' do
            post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json

            expect(Ticket::Article.last.attachments).to be_empty
          end
        end

        context 'when receiving duplicate messages' do
          let(:payload_file) { 'webhook1_tweet.json' }

          it 'still returns 200' do
            2.times { post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json }

            expect(response).to have_http_status(:ok)
          end

          it 'does not create duplicate articles' do
            expect do
              2.times { post '/api/v1/channels_twitter_webhook', **webhook_payload, as: :json }
            end.to change { Ticket::Article.count }.by(1)
          end
        end
      end
    end
  end
end
