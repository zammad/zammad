require 'rails_helper'

RSpec.describe 'Integration Twitter Webhook', type: :request do

  let(:agent_user) do
    create(:agent_user)
  end

  before(:each) do
    @external_credential = ExternalCredential.create!(
      name: 'twitter',
      credentials: {
        consumer_key: 'CCC',
        consumer_secret: 'DDD',
      }
    )
    @channel = Channel.create!(
      group_id: nil,
      area: 'Twitter::Account',
      options: {
        adapter: 'twitter',
        user: {
          id: 123,
          screen_name: 'zammadhq',
          name: 'Zammad HQ',
        },
        auth: {
          external_credential_id: 1,
          oauth_token: 'AAA',
          oauth_token_secret: 'BBB',
          consumer_key: 'CCC',
          consumer_secret: 'DDD',
        },
        sync: {
          limit: 20,
          search: [{ term: '#zammad', group_id: Group.first.id.to_s }, { term: '#hello1234', group_id: Group.first.id.to_s }],
          mentions: { group_id: Group.first.id.to_s },
          direct_messages: { group_id: Group.first.id.to_s },
          track_retweets: false
        }
      },
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

  describe 'request verify' do

    it 'does at config check' do
      Cache.write('external_credential_twitter', @external_credential.credentials)
      @external_credential.destroy
      params = {
        crc_token: 'some_random',
        nonce: 'some_nonce',
      }
      get '/api/v1/channels_twitter_webhook', params: params, headers: { 'x-twitter-webhooks-signature' => 'something' }, as: :json
      expect(response).to have_http_status(200)
      expect(json_response['response_token']).to eq('sha256=VE19eUk6krbdSqWPdvH71xtFhApBAU81uPW3UT65vOs=')
    end

    it 'does configured check' do
      Cache.delete('external_credential_twitter')
      params = {
        crc_token: 'some_random',
        nonce: 'some_nonce',
      }
      get '/api/v1/channels_twitter_webhook', params: params, headers: { 'x-twitter-webhooks-signature' => 'something' }, as: :json
      expect(response).to have_http_status(200)
      expect(json_response['response_token']).to eq('sha256=VE19eUk6krbdSqWPdvH71xtFhApBAU81uPW3UT65vOs=')
    end

  end

  describe 'request incoming - base' do

    it 'does without x-twitter-webhooks-signature header check' do
      params = {}
      post '/api/v1/channels_twitter_webhook', params: params, as: :json
      expect(response).to have_http_status(422)
      expect(json_response['error']).to eq('Missing \'x-twitter-webhooks-signature\' header')
    end

    it 'does no external_credential check' do
      @external_credential.destroy
      params = {}
      post '/api/v1/channels_twitter_webhook', params: params, headers: { 'x-twitter-webhooks-signature' => 'something' }, as: :json
      expect(response).to have_http_status(422)
      expect(json_response['error']).to eq('No such external_credential \'twitter\'!')
    end

    it 'does invalid token check' do
      params = {}
      post '/api/v1/channels_twitter_webhook', params: params, headers: { 'x-twitter-webhooks-signature' => 'something' }, as: :json
      expect(response).to have_http_status(401)
      expect(json_response['error']).to eq('Not authorized')
    end

    it 'does existing for_user_id check' do
      params = { key: 'value' }
      post '/api/v1/channels_twitter_webhook', params: params, headers: { 'x-twitter-webhooks-signature' => 'sha256=EERHBy/k17v+SuT+K0OXuwhJtKnPtxi0n/Y4Wye4kVU=' }, as: :json
      expect(response).to have_http_status(422)
      expect(json_response['error']).to eq('Missing \'for_user_id\' in payload!')
    end

    it 'does invalid user check' do
      params = { for_user_id: 'not_existing', key: 'value' }
      post '/api/v1/channels_twitter_webhook', params: params, headers: { 'x-twitter-webhooks-signature' => 'sha256=QaJiQl/4WRp/GF37b+eAdF6kPgptjDCLOgAIIbB1s0I=' }, as: :json
      expect(response).to have_http_status(422)
      expect(json_response['error']).to eq('No such channel for user id \'not_existing\'!')
    end

    it 'does valid token check' do
      params = { for_user_id: 123, key: 'value' }
      post '/api/v1/channels_twitter_webhook', params: params, headers: { 'x-twitter-webhooks-signature' => 'sha256=JjEmBe1lVKT8XldrYUKibF+D5ehp8f0jDk3PXZSHEWI=' }, as: :json
      expect(response).to have_http_status(200)
    end
  end

  describe 'request incoming direct message' do
    it 'create new ticket via tweet' do
      post '/api/v1/channels_twitter_webhook', params: read_messaage('webhook1_direct_message'), headers: { 'x-twitter-webhooks-signature' => 'sha256=xXu7qrPhqXfo8Ot14c0si9HrdQdBNru5fkSdoMZi+Ms=' }, as: :json

      expect(response).to have_http_status(200)
      article = Ticket::Article.find_by(message_id: '1062015437679050760')
      expect(article).to be_present
      expect(article.from).to eq('@zammadhq')
      expect(article.to).to eq('@medenhofer')
      expect(article.created_by.login).to eq('zammadhq')
      expect(article.created_by.firstname).to eq('Zammad')
      expect(article.created_by.lastname).to eq('Hq')
      expect(article.attachments.count).to eq(0)

      ticket = article.ticket
      expect(ticket.title).to eq('Hey! Hello!')
      expect(ticket.state.name).to eq('closed')
      expect(ticket.priority.name).to eq('2 normal')
      expect(ticket.customer.login).to eq('zammadhq')
      expect(ticket.customer.firstname).to eq('Zammad')
      expect(ticket.customer.lastname).to eq('Hq')
      expect(ticket.created_by.login).to eq('zammadhq')
      expect(ticket.created_by.firstname).to eq('Zammad')
      expect(ticket.created_by.lastname).to eq('Hq')

      post '/api/v1/channels_twitter_webhook', params: read_messaage('webhook2_direct_message'), headers: { 'x-twitter-webhooks-signature' => 'sha256=wYiCk7gfAgrnerCpj3XD58hozfVDjcQvcYPZCFH+stU=' }, as: :json

      article = Ticket::Article.find_by(message_id: '1063077238797725700')
      expect(article).to be_present
      expect(article.to).to eq('@zammadhq')
      expect(article.from).to eq('@medenhofer')
      expect(article.body).to eq("Hello Zammad #zammad @znuny\n\nYeah! https://twitter.com/messages/media/1063077238797725700")
      expect(article.created_by.login).to eq('medenhofer')
      expect(article.created_by.firstname).to eq('Martin')
      expect(article.created_by.lastname).to eq('Edenhofer')
      expect(article.attachments.count).to eq(0)

      ticket = article.ticket
      expect(ticket.title).to eq('Hello Zammad #zammad @znuny  Yeah! https://t.co/UfaCwi9cUb')
      expect(ticket.state.name).to eq('new')
      expect(ticket.priority.name).to eq('2 normal')
      expect(ticket.customer.login).to eq('medenhofer')
      expect(ticket.customer.firstname).to eq('Martin')
      expect(ticket.customer.lastname).to eq('Edenhofer')

      post '/api/v1/channels_twitter_webhook', params: read_messaage('webhook3_direct_message'), headers: { 'x-twitter-webhooks-signature' => 'sha256=OTguUdchBdxNal/csZsRkytKL5srrUuezZ3hp/2E404=' }, as: :json

      article = Ticket::Article.find_by(message_id: '1063077238797725701')
      expect(article).to be_present
      expect(article.to).to eq('@zammadhq')
      expect(article.from).to eq('@medenhofer')
      expect(article.body).to eq('Hello again!')
      expect(article.created_by.login).to eq('medenhofer')
      expect(article.created_by.firstname).to eq('Martin')
      expect(article.created_by.lastname).to eq('Edenhofer')
      expect(article.ticket.id).to eq(ticket.id)
      expect(article.attachments.count).to eq(0)

      ticket = article.ticket
      expect(ticket.title).to eq('Hello Zammad #zammad @znuny  Yeah! https://t.co/UfaCwi9cUb')
      expect(ticket.state.name).to eq('new')
      expect(ticket.priority.name).to eq('2 normal')
      expect(ticket.customer.login).to eq('medenhofer')
      expect(ticket.customer.firstname).to eq('Martin')
      expect(ticket.customer.lastname).to eq('Edenhofer')
    end

    it 'check duplicate' do
      post '/api/v1/channels_twitter_webhook', params: read_messaage('webhook1_direct_message'), headers: { 'x-twitter-webhooks-signature' => 'sha256=xXu7qrPhqXfo8Ot14c0si9HrdQdBNru5fkSdoMZi+Ms=' }, as: :json

      expect(response).to have_http_status(200)

      post '/api/v1/channels_twitter_webhook', params: read_messaage('webhook1_direct_message'), headers: { 'x-twitter-webhooks-signature' => 'sha256=xXu7qrPhqXfo8Ot14c0si9HrdQdBNru5fkSdoMZi+Ms=' }, as: :json

      expect(response).to have_http_status(200)

      expect(Ticket::Article.where(message_id: '1062015437679050760').count).to eq(1)
    end
  end

  describe 'request incoming direct message' do

    it 'create new ticket via tweet' do

      stub_request(:get, 'http://pbs.twimg.com/profile_images/785412960797745152/wxdIvejo_bigger.jpg')
        .to_return(status: 200, body: 'some_content')

      stub_request(:get, 'https://pbs.twimg.com/media/DsFKfJRWkAAFEbo.jpg')
        .to_return(status: 200, body: 'some_content')

      post '/api/v1/channels_twitter_webhook', params: read_messaage('webhook1_tweet'), headers: { 'x-twitter-webhooks-signature' => 'sha256=DmARpz6wdgte6Vj+ePeqC+RHvEDokmwOIIqr4//utkk=' }, as: :json

      expect(response).to have_http_status(200)
      article = Ticket::Article.find_by(message_id: '1063212927510081536')
      expect(article).to be_present
      expect(article.from).to eq('@zammadhq')
      expect(article.to).to eq('@medenhofer')
      expect(article.body).to eq('Hey @medenhofer !  #hello1234 https://twitter.com/zammadhq/status/1063212927510081536/photo/1')
      expect(article.created_by.login).to eq('zammadhq')
      expect(article.created_by.firstname).to eq('Zammad')
      expect(article.created_by.lastname).to eq('Hq')
      expect(article.attachments.count).to eq(1)
      expect(article.attachments[0].filename).to eq('DsFKfJRWkAAFEbo.jpg')

      ticket = article.ticket
      expect(ticket.title).to eq('Hey @medenhofer !  #hello1234 https://t.co/f1kffFlwpN')
      expect(ticket.state.name).to eq('closed')
      expect(ticket.priority.name).to eq('2 normal')
      expect(ticket.customer.login).to eq('zammadhq')
      expect(ticket.customer.firstname).to eq('Zammad')
      expect(ticket.customer.lastname).to eq('Hq')
      expect(ticket.created_by.login).to eq('zammadhq')
      expect(ticket.created_by.firstname).to eq('Zammad')
      expect(ticket.created_by.lastname).to eq('Hq')
    end

    it 'create new ticket via tweet extended_tweet' do

      stub_request(:get, 'http://pbs.twimg.com/profile_images/794220000450150401/D-eFg44R_bigger.jpg')
        .to_return(status: 200, body: 'some_content')

      post '/api/v1/channels_twitter_webhook', params: read_messaage('webhook2_tweet'), headers: { 'x-twitter-webhooks-signature' => 'sha256=U7bglX19JitI2xuvyONAc0d/fowIFEeUzkEgnWdGyUM=' }, as: :json

      expect(response).to have_http_status(200)
      article = Ticket::Article.find_by(message_id: '1065035365336141825')
      expect(article).to be_present
      expect(article.from).to eq('@medenhofer')
      expect(article.to).to eq('@znuny')
      expect(article.body).to eq('@znuny Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lore')
      expect(article.created_by.login).to eq('medenhofer')
      expect(article.created_by.firstname).to eq('Martin')
      expect(article.created_by.lastname).to eq('Edenhofer')
      expect(article.attachments.count).to eq(0)

      ticket = article.ticket
      expect(ticket.title).to eq('@znuny Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy ...')
      expect(ticket.state.name).to eq('new')
      expect(ticket.priority.name).to eq('2 normal')
      expect(ticket.customer.login).to eq('medenhofer')
      expect(ticket.customer.firstname).to eq('Martin')
      expect(ticket.customer.lastname).to eq('Edenhofer')
      expect(ticket.created_by.login).to eq('medenhofer')
      expect(ticket.created_by.firstname).to eq('Martin')
      expect(ticket.created_by.lastname).to eq('Edenhofer')
    end

    it 'check duplicate' do
      post '/api/v1/channels_twitter_webhook', params: read_messaage('webhook1_tweet'), headers: { 'x-twitter-webhooks-signature' => 'sha256=DmARpz6wdgte6Vj+ePeqC+RHvEDokmwOIIqr4//utkk=' }, as: :json

      expect(response).to have_http_status(200)

      post '/api/v1/channels_twitter_webhook', params: read_messaage('webhook1_tweet'), headers: { 'x-twitter-webhooks-signature' => 'sha256=DmARpz6wdgte6Vj+ePeqC+RHvEDokmwOIIqr4//utkk=' }, as: :json

      expect(response).to have_http_status(200)

      expect(Ticket::Article.where(message_id: '1063212927510081536').count).to eq(1)
    end
  end

  def read_messaage(file)
    JSON.parse(File.read(Rails.root.join('test', 'data', 'twitter', "#{file}.json")))
  end
end
