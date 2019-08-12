require 'rails_helper'

RSpec.describe 'Telegram', type: :request do

  describe 'request handling' do

    it 'does basic call' do
      Ticket.destroy_all

      # configure telegram channel
      token    = 'valid_token'
      bot_id   = 123_456_789
      group_id = Group.find_by(name: 'Users').id

      UserInfo.current_user_id = 1
      Channel.where(area: 'Telegram::Bot').destroy_all

      # try with invalid token
      stub_request(:post, 'https://api.telegram.org/botnot_existing/getMe')
        .to_return(status: 404, body: '{"ok":false,"error_code":404,"description":"Not Found"}', headers: {})

      expect do
        Telegram.check_token('not_existing')
      end.to raise_error(RuntimeError)

      # try valid token
      stub_request(:post, "https://api.telegram.org/bot#{token}/getMe")
        .to_return(status: 200, body: "{\"ok\":true,\"result\":{\"id\":#{bot_id},\"first_name\":\"Chrispresso Customer Service\",\"username\":\"ChrispressoBot\"}}", headers: {})

      bot = Telegram.check_token(token)
      expect(bot['id']).to eq(bot_id)

      stub_request(:post, "https://api.telegram.org/bot#{token}/getMe")
        .to_return(status: 200, body: "{\"ok\":true,\"result\":{\"id\":#{bot_id},\"first_name\":\"Chrispresso Customer Service\",\"username\":\"ChrispressoBot\"}}", headers: {})

      Setting.set('http_type', 'http')
      expect do
        Telegram.create_or_update_channel(token, { group_id: group_id, welcome: 'hi!', goodbye: 'goodbye' })
      end.to raise_error(RuntimeError)

      # try invalid port
      stub_request(:post, "https://api.telegram.org:443/bot#{token}/getMe")
        .to_return(status: 200, body: "{\"ok\":true,\"result\":{\"id\":#{bot_id},\"first_name\":\"Chrispresso Customer Service\",\"username\":\"ChrispressoBot\"}}", headers: {})
      stub_request(:post, "https://api.telegram.org:443/bot#{token}/setWebhook")
        .with(body: { 'url' => "https://somehost.example.com:12345/api/v1/channels_telegram_webhook/callback_token?bid=#{bot_id}" })
        .to_return(status: 400, body: '{"ok":false,"error_code":400,"description":"Bad Request: bad webhook: Webhook can be set up only on ports 80, 88, 443 or 8443"}', headers: {})

      Setting.set('http_type', 'https')
      Setting.set('fqdn', 'somehost.example.com:12345')
      expect do
        Telegram.create_or_update_channel(token, { group_id: group_id, welcome: 'hi!', goodbye: 'goodbye' })
      end.to raise_error(RuntimeError)

      # try invalid host
      stub_request(:post, "https://api.telegram.org:443/bot#{token}/setWebhook")
        .with(body: { 'url' => "https://somehost.example.com/api/v1/channels_telegram_webhook/callback_token?bid=#{bot_id}" })
        .to_return(status: 400, body: '{"ok":false,"error_code":400,"description":"Bad Request: bad webhook: getaddrinfo: Name or service not known"}', headers: {})

      Setting.set('fqdn', 'somehost.example.com')
      expect do
        Telegram.create_or_update_channel(token, { group_id: group_id, welcome: 'hi!', goodbye: 'goodbye' })
      end.to raise_error(RuntimeError)

      # valid token, host and port
      stub_request(:post, "https://api.telegram.org:443/bot#{token}/setWebhook")
        .with(body: { 'url' => "https://example.com/api/v1/channels_telegram_webhook/callback_token?bid=#{bot_id}" })
        .to_return(status: 200, body: '{"ok":true,"result":true,"description":"Webhook was set"}', headers: {})

      Setting.set('fqdn', 'example.com')
      channel = Telegram.create_or_update_channel(token, { group_id: group_id, welcome: 'hi!', goodbye: 'goodbye' })
      UserInfo.current_user_id = nil

      # start communication #1
      post '/api/v1/channels/telegram_webhook', params: read_message('personal1_message_start'), as: :json
      expect(response).to have_http_status(:not_found)

      post '/api/v1/channels_telegram_webhook/not_existing', params: read_message('personal1_message_start'), as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['error']).to eq('bot id is missing')

      callback_url = "/api/v1/channels_telegram_webhook/not_existing?bid=#{channel.options[:bot][:id]}"
      post callback_url, params: read_message('personal1_message_start'), as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['error']).to eq('invalid callback token')

      callback_url = "/api/v1/channels_telegram_webhook/#{channel.options[:callback_token]}?bid=#{channel.options[:bot][:id]}"
      post callback_url, params: read_message('personal1_message_start'), as: :json
      expect(response).to have_http_status(:ok)

      # send message1
      post callback_url, params: read_message('personal1_message_content1'), as: :json
      expect(response).to have_http_status(:ok)
      expect(Ticket.count).to eq(1)
      ticket = Ticket.last
      expect(ticket.title).to eq('Hello, I need your Help')
      expect(ticket.state.name).to eq('new')
      expect(ticket.articles.count).to eq(1)
      expect(ticket.articles.first.body).to eq('Hello, I need your Help')
      expect(ticket.articles.first.content_type).to eq('text/plain')

      # send channel message1
      post callback_url, params: read_message('channel1_message_content1'), as: :json
      expect(response).to have_http_status(:ok)
      expect(Ticket.count).to eq(1)
      ticket = Ticket.last
      expect(ticket.title).to eq('Hello, I need your Help')
      expect(ticket.state.name).to eq('new')
      expect(ticket.articles.count).to eq(1)
      expect(ticket.articles.first.body).to eq('Hello, I need your Help')
      expect(ticket.articles.first.content_type).to eq('text/plain')

      # edit channel message1
      post callback_url, params: read_message('channel2_message_content1'), as: :json
      expect(response).to have_http_status(:ok)
      expect(Ticket.count).to eq(1)
      ticket = Ticket.last
      expect(ticket.title).to eq('Hello, I need your Help')
      expect(ticket.state.name).to eq('new')
      expect(ticket.articles.count).to eq(1)
      expect(ticket.articles.first.body).to eq('Hello, I need your Help')
      expect(ticket.articles.first.content_type).to eq('text/plain')

      # send same message again, ignore it
      post callback_url, params: read_message('personal1_message_content1'), as: :json
      expect(response).to have_http_status(:ok)
      ticket = Ticket.last
      expect(ticket.title).to eq('Hello, I need your Help')
      expect(ticket.state.name).to eq('new')
      expect(ticket.articles.count).to eq(1)
      expect(ticket.articles.first.body).to eq('Hello, I need your Help')
      expect(ticket.articles.first.content_type).to eq('text/plain')

      # send message2
      post callback_url, params: read_message('personal1_message_content2'), as: :json
      expect(response).to have_http_status(:ok)
      ticket = Ticket.last
      expect(ticket.title).to eq('Hello, I need your Help')
      expect(ticket.state.name).to eq('new')
      expect(ticket.articles.count).to eq(2)
      expect(ticket.articles.last.body).to eq('Hello, I need your Help 2')
      expect(ticket.articles.last.content_type).to eq('text/plain')

      # send end message
      post callback_url, params: read_message('personal1_message_end'), as: :json
      expect(response).to have_http_status(:ok)
      ticket = Ticket.last
      expect(ticket.title).to eq('Hello, I need your Help')
      expect(ticket.state.name).to eq('closed')
      expect(ticket.articles.count).to eq(2)
      expect(ticket.articles.last.body).to eq('Hello, I need your Help 2')
      expect(ticket.articles.last.content_type).to eq('text/plain')

      # start communication #2
      post callback_url, params: read_message('personal2_message_start'), as: :json
      expect(response).to have_http_status(:ok)

      # send message1
      post callback_url, params: read_message('personal2_message_content1'), as: :json
      expect(response).to have_http_status(:ok)
      expect(Ticket.count).to eq(2)
      ticket = Ticket.last
      expect(ticket.title).to eq('Can you help me with my feature?')
      expect(ticket.state.name).to eq('new')
      expect(ticket.articles.count).to eq(1)
      expect(ticket.articles.first.body).to eq('Can you help me with my feature?')
      expect(ticket.articles.first.content_type).to eq('text/plain')

      # send message2
      post callback_url, params: read_message('personal2_message_content2'), as: :json
      expect(response).to have_http_status(:ok)
      expect(Ticket.count).to eq(2)
      ticket = Ticket.last
      expect(ticket.title).to eq('Can you help me with my feature?')
      expect(ticket.state.name).to eq('new')
      expect(ticket.articles.count).to eq(2)
      expect(ticket.articles.last.body).to eq('Yes of course! <b>lalal</b>')
      expect(ticket.articles.last.content_type).to eq('text/plain')

      # start communication #3
      post callback_url, params: read_message('personal3_message_start'), as: :json
      expect(response).to have_http_status(:ok)

      # send message1
      post callback_url, params: read_message('personal3_message_content1'), as: :json
      expect(response).to have_http_status(:ok)
      expect(Ticket.count).to eq(3)
      ticket = Ticket.last
      expect(ticket.title).to eq('Can you help me with my feature?')
      expect(ticket.state.name).to eq('new')
      expect(ticket.articles.count).to eq(1)
      expect(ticket.articles.last.body).to eq('Can you help me with my feature?')
      expect(ticket.articles.last.content_type).to eq('text/plain')

      # send message2
      stub_request(:post, "https://api.telegram.org/bot#{token}/getFile")
        .with(body: { 'file_id' => 'ABC-123VabcOcv123w0ABHywrcPqfrbAYIABC' })
        .to_return(status: 200, body: '{"result":{"file_size":123,"file_id":"ABC-123VabcOcv123w0ABHywrcPqfrbAYIABC","file_path":"abc123"}}', headers: {})
      stub_request(:get, "https://api.telegram.org/file/bot#{token}/abc123")
        .to_return(status: 200, body: 'ABC1', headers: {})

      post callback_url, params: read_message('personal3_message_content2'), as: :json
      expect(response).to have_http_status(:ok)
      expect(Ticket.count).to eq(3)
      ticket = Ticket.last
      expect(ticket.title).to eq('Can you help me with my feature?')
      expect(ticket.state.name).to eq('new')
      expect(ticket.articles.count).to eq(2)
      expect(ticket.articles.last.body).to match(/<img style="width:360px;height:327px;"/i)
      expect(ticket.articles.last.content_type).to eq('text/html')

      # send channel message 3
      post callback_url, params: read_message('channel1_message_content3'), as: :json
      expect(response).to have_http_status(:ok)
      expect(Ticket.count).to eq(3)
      ticket = Ticket.last
      expect(ticket.title).to eq('Can you help me with my feature?')
      expect(ticket.state.name).to eq('new')
      expect(ticket.articles.count).to eq(2)
      expect(ticket.articles.last.body).to match(/<img style="width:360px;height:327px;"/i)
      expect(ticket.articles.last.content_type).to eq('text/html')

      # send message3
      stub_request(:post, "https://api.telegram.org/bot#{token}/getFile")
        .with(body: { 'file_id' => 'AAQCABO0I4INAATATQAB5HWPq4XgxQACAg' })
        .to_return(status: 200, body: '{"result":{"file_size":123,"file_id":"ABC-123AAQCABO0I4INAATATQAB5HWPq4XgxQACAg","file_path":"abc123"}}', headers: {})
      stub_request(:get, "https://api.telegram.org/file/bot#{token}/abc123")
        .to_return(status: 200, body: 'ABC2', headers: {})
      stub_request(:post, "https://api.telegram.org/bot#{token}/getFile")
        .with(body: { 'file_id' => 'BQADAgADDgAD7x6ZSC_-1LMkOEmoAg' })
        .to_return(status: 200, body: '{"result":{"file_size":123,"file_id":"ABC-123BQADAgADDgAD7x6ZSC_-1LMkOEmoAg","file_path":"abc123"}}', headers: {})

      post callback_url, params: read_message('personal3_message_content3'), as: :json
      expect(response).to have_http_status(:ok)
      expect(Ticket.count).to eq(3)
      ticket = Ticket.last
      expect(ticket.title).to eq('Can you help me with my feature?')
      expect(ticket.state.name).to eq('new')
      expect(ticket.articles.count).to eq(3)
      expect(ticket.articles.last.body).to match(/<img style="width:200px;height:200px;"/i)
      expect(ticket.articles.last.content_type).to eq('text/html')
      expect(ticket.articles.last.attachments.count).to eq(1)

      # send channel message 2
      post callback_url, params: read_message('channel1_message_content2'), as: :json
      expect(response).to have_http_status(:ok)
      expect(Ticket.count).to eq(3)
      ticket = Ticket.last
      expect(ticket.title).to eq('Can you help me with my feature?')
      expect(ticket.state.name).to eq('new')
      expect(ticket.articles.count).to eq(3)
      expect(ticket.articles.last.body).to match(/<img style="width:200px;height:200px;"/i)
      expect(ticket.articles.last.content_type).to eq('text/html')
      expect(ticket.articles.last.attachments.count).to eq(1)

      # update message1
      post callback_url, params: read_message('personal3_message_content4'), as: :json
      expect(response).to have_http_status(:ok)
      expect(Ticket.count).to eq(3)
      ticket = Ticket.last
      expect(ticket.title).to eq('Can you help me with my feature?')
      expect(ticket.state.name).to eq('new')
      expect(ticket.articles.count).to eq(3)
      expect(ticket.articles.last.body).to match(/<img style="width:200px;height:200px;"/i)
      expect(ticket.articles.last.content_type).to eq('text/html')
      expect(ticket.articles.last.attachments.count).to eq(1)

      expect(ticket.articles.first.body).to eq('UPDATE: 1231444')
      expect(ticket.articles.first.content_type).to eq('text/plain')

      # send voice5
      stub_request(:post, "https://api.telegram.org/bot#{token}/getFile")
        .with(body: { 'file_id' => 'AwADAgADVQADCEIYSZwyOmSZK9iZAg' })
        .to_return(status: 200, body: '{"result":{"file_size":123,"file_id":"ABC-123AwADAgADVQADCEIYSZwyOmSZK9iZAg","file_path":"abc123"}}', headers: {})

      post callback_url, params: read_message('personal3_message_content5'), as: :json
      expect(response).to have_http_status(:ok)
      expect(Ticket.count).to eq(3)
      ticket = Ticket.last
      expect(ticket.title).to eq('Can you help me with my feature?')
      expect(ticket.state.name).to eq('new')
      expect(ticket.articles.count).to eq(4)
      expect(ticket.articles.last.content_type).to eq('text/html')
      expect(ticket.articles.last.attachments.count).to eq(1)

      # send channel message 4 with voice
      post callback_url, params: read_message('channel1_message_content4'), as: :json
      expect(response).to have_http_status(:ok)
      expect(Ticket.count).to eq(3)
      ticket = Ticket.last
      expect(ticket.title).to eq('Can you help me with my feature?')
      expect(ticket.state.name).to eq('new')
      expect(ticket.articles.count).to eq(4)
      expect(ticket.articles.last.content_type).to eq('text/html')
      expect(ticket.articles.last.attachments.count).to eq(1)

      # start communication #4 - with sticker
      stub_request(:post, "https://api.telegram.org/bot#{token}/getFile")
        .with(body: { 'file_id' => 'AAQDABO3-e4qAASs6ZOjJUT7tQ4lAAIC' })
        .to_return(status: 200, body: '{"result":{"file_size":123,"file_id":"ABC-123AAQDABO3-e4qAASs6ZOjJUT7tQ4lAAIC","file_path":"abc123"}}', headers: {})
      stub_request(:post, "https://api.telegram.org/bot#{token}/getFile")
        .with(body: { 'file_id' => 'BQADAwAD0QIAAqbJWAAB8OkQqgtDQe0C' })
        .to_return(status: 200, body: '{"result":{"file_size":123,"file_id":"ABC-123BQADAwAD0QIAAqbJWAAB8OkQqgtDQe0C","file_path":"abc123"}}', headers: {})

      post callback_url, params: read_message('personal4_message_content1'), as: :json
      expect(response).to have_http_status(:ok)
      expect(Ticket.count).to eq(4)
      ticket = Ticket.last
      if Rails.application.config.db_4bytes_utf8
        expect(ticket.title).to eq('💻')
      else
        expect(ticket.title).to eq('')
      end
      expect(ticket.state.name).to eq('new')
      expect(ticket.articles.count).to eq(1)
      expect(ticket.articles.last.body).to match(/<img style="/i)
      expect(ticket.articles.last.content_type).to eq('text/html')
      expect(ticket.articles.last.attachments.count).to eq(1)

      # send channel message #5 with sticker
      post callback_url, params: read_message('channel1_message_content5'), as: :json
      expect(response).to have_http_status(:ok)
      expect(Ticket.count).to eq(4)
      ticket = Ticket.last
      if Rails.application.config.db_4bytes_utf8
        expect(ticket.title).to eq('💻')
      else
        expect(ticket.title).to eq('')
      end
      expect(ticket.state.name).to eq('new')
      expect(ticket.articles.count).to eq(1)
      expect(ticket.articles.last.body).to match(/<img style="/i)
      expect(ticket.articles.last.content_type).to eq('text/html')
      expect(ticket.articles.last.attachments.count).to eq(1)

      # start communication #5 - with photo
      stub_request(:post, "https://api.telegram.org/bot#{token}/getFile")
        .with(body: { 'file_id' => 'AgADAgADwacxGxk5MUmim45lijOwsKk1Sw0ABNQoaI8BwR_z_2MFAAEC' })
        .to_return(status: 200, body: '{"result":{"file_size":123,"file_id":"ABC-123AgADAgADwacxGxk5MUmim45lijOwsKk1Sw0ABNQoaI8BwR_z_2MFAAEC","file_path":"abc123"}}', headers: {})

      post callback_url, params: read_message('personal5_message_content1'), as: :json
      expect(response).to have_http_status(:ok)
      expect(Ticket.count).to eq(5)
      ticket = Ticket.last
      expect(ticket.title).to eq('-')
      expect(ticket.state.name).to eq('new')
      expect(ticket.articles.count).to eq(1)
      expect(ticket.articles.last.body).to match(/<img style="/i)
      expect(ticket.articles.last.content_type).to eq('text/html')
      expect(ticket.articles.last.attachments.count).to eq(0)

      post callback_url, params: read_message('personal5_message_content2'), as: :json
      expect(response).to have_http_status(:ok)
      expect(Ticket.count).to eq(5)
      ticket = Ticket.last
      expect(ticket.title).to eq('Hello, I need your Help')
      expect(ticket.state.name).to eq('new')
      expect(ticket.articles.count).to eq(2)
      expect(ticket.articles.last.body).to match(/Hello, I need your Help/i)
      expect(ticket.articles.last.content_type).to eq('text/plain')
      expect(ticket.articles.last.attachments.count).to eq(0)
    end

    it 'with two bots and different groups' do
      Ticket.destroy_all

      # configure telegram channel
      token1 = 'valid_token1'
      token2 = 'valid_token2'

      bot_id1 = 123_456_789
      bot_id2 = 987_654_321

      group1 = create(:group)
      group2 = create(:group)

      UserInfo.current_user_id = 1
      Channel.where(area: 'Telegram::Bot').destroy_all

      Setting.set('http_type', 'https')
      Setting.set('fqdn', 'example.com')

      # channel 1 - try valid token
      stub_request(:post, "https://api.telegram.org/bot#{token1}/getMe")
        .to_return(status: 200, body: "{\"ok\":true,\"result\":{\"id\":#{bot_id1},\"first_name\":\"Chrispresso Customer Service\",\"username\":\"ChrispressoBot1\"}}", headers: {})

      bot1 = Telegram.check_token(token1)
      expect(bot1['id']).to eq(bot_id1)

      # channel 1 - valid token, host and port
      stub_request(:post, "https://api.telegram.org:443/bot#{token1}/setWebhook")
        .with(body: { 'url' => "https://example.com/api/v1/channels_telegram_webhook/callback_token?bid=#{bot_id1}" })
        .to_return(status: 200, body: '{"ok":true,"result":true,"description":"Webhook was set"}', headers: {})

      channel1 = Telegram.create_or_update_channel(token1, { group_id: group1.id, welcome: 'hi!', goodbye: 'goodbye' })

      # start communication #1
      callback_url1 = "/api/v1/channels_telegram_webhook/#{channel1.options[:callback_token]}?bid=#{channel1.options[:bot][:id]}"
      post callback_url1, params: read_message('personal1_message_start'), as: :json
      expect(response).to have_http_status(:ok)

      # send message1
      post callback_url1, params: read_message('personal1_message_content1'), as: :json
      expect(response).to have_http_status(:ok)
      expect(Ticket.count).to eq(1)
      ticket1 = Ticket.last
      expect(ticket1.title).to eq('Hello, I need your Help')
      expect(ticket1.state.name).to eq('new')
      expect(ticket1.articles.count).to eq(1)
      expect(ticket1.articles.first.body).to eq('Hello, I need your Help')
      expect(ticket1.articles.first.content_type).to eq('text/plain')

      expect(ticket1.articles.first.from).to eq('Test Firstname Test Lastname')
      expect(ticket1.articles.first.to).to eq('@ChrispressoBot1')

      # channel 2 - try valid token
      UserInfo.current_user_id = 1
      stub_request(:post, "https://api.telegram.org/bot#{token2}/getMe")
        .to_return(status: 200, body: "{\"ok\":true,\"result\":{\"id\":#{bot_id2},\"first_name\":\"Chrispresso Customer Service\",\"username\":\"ChrispressoBot2\"}}", headers: {})

      bot2 = Telegram.check_token(token2)
      expect(bot2['id']).to eq(bot_id2)

      # channel 2 - valid token, host and port
      stub_request(:post, "https://api.telegram.org:443/bot#{token2}/setWebhook")
        .with(body: { 'url' => "https://example.com/api/v1/channels_telegram_webhook/callback_token?bid=#{bot_id2}" })
        .to_return(status: 200, body: '{"ok":true,"result":true,"description":"Webhook was set"}', headers: {})

      channel2 = Telegram.create_or_update_channel(token2, { group_id: group2.id, welcome: 'hi!', goodbye: 'goodbye' })

      # start communication #1
      callback_url2 = "/api/v1/channels_telegram_webhook/#{channel2.options[:callback_token]}?bid=#{channel2.options[:bot][:id]}"
      post callback_url2, params: read_message('personal3_message_start'), as: :json
      expect(response).to have_http_status(:ok)

      # send message2
      post callback_url2, params: read_message('personal3_message_content1'), as: :json
      expect(response).to have_http_status(:ok)
      expect(Ticket.count).to eq(2)
      ticket2 = Ticket.last
      expect(ticket2.title).to eq('Can you help me with my feature?')
      expect(ticket2.state.name).to eq('new')
      expect(ticket2.articles.count).to eq(1)
      expect(ticket2.articles.first.body).to eq('Can you help me with my feature?')
      expect(ticket2.articles.first.content_type).to eq('text/plain')

      expect(ticket2.articles.first.from).to eq('Test Firstname2 Test Lastname2')
      expect(ticket2.articles.first.to).to eq('@ChrispressoBot2')
    end

    def read_message(file)
      JSON.parse(File.read(Rails.root.join('test', 'data', 'telegram', "#{file}.json")))
    end
  end
end
