# encoding: utf-8
require 'test_helper'
require 'rexml/document'
require 'webmock/minitest'

class TelegramControllerTest < ActionDispatch::IntegrationTest
  setup do
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }
  end

  test 'basic call' do
    Ticket.destroy_all

    # configure telegram channel
    token = 'valid_token'
    bot_id = 123_456_789
    group_id = Group.find_by(name: 'Users').id

    UserInfo.current_user_id = 1
    Channel.where(area: 'Telegram::Bot').destroy_all

    # try with invalid token
    stub_request(:get, 'https://api.telegram.org/botnot_existing/getMe')
      .to_return(status: 404, body: '{"ok":false,"error_code":404,"description":"Not Found"}', headers: {})

    assert_raises(RuntimeError) {
      Telegram.check_token('not_existing')
    }

    # try valid token
    stub_request(:get, "https://api.telegram.org/bot#{token}/getMe")
      .to_return(status: 200, body: "{\"ok\":true,\"result\":{\"id\":#{bot_id},\"first_name\":\"Chrispresso Customer Service\",\"username\":\"ChrispressoBot\"}}", headers: {})

    bot = Telegram.check_token(token)
    assert_equal(bot_id, bot['id'])

    stub_request(:get, "https://api.telegram.org/bot#{token}/getMe")
      .to_return(status: 200, body: "{\"ok\":true,\"result\":{\"id\":#{bot_id},\"first_name\":\"Chrispresso Customer Service\",\"username\":\"ChrispressoBot\"}}", headers: {})

    Setting.set('http_type', 'http')
    assert_raises(RuntimeError) {
      Telegram.create_or_update_channel(token, { group_id: group_id, welcome: 'hi!' })
    }

    # try invalid port
    stub_request(:get, "https://api.telegram.org:443/bot#{token}/getMe")
      .to_return(status: 200, body: "{\"ok\":true,\"result\":{\"id\":#{bot_id},\"first_name\":\"Chrispresso Customer Service\",\"username\":\"ChrispressoBot\"}}", headers: {})
    stub_request(:get, "https://api.telegram.org:443/bot#{token}/setWebhook?url=https://somehost.example.com:12345/api/v1/channels_telegram_webhook/callback_token?bid=#{bot_id}")
      .to_return(status: 400, body: '{"ok":false,"error_code":400,"description":"Bad Request: bad webhook: Webhook can be set up only on ports 80, 88, 443 or 8443"}', headers: {})

    Setting.set('http_type', 'https')
    Setting.set('fqdn', 'somehost.example.com:12345')
    assert_raises(RuntimeError) {
      Telegram.create_or_update_channel(token, { group_id: group_id, welcome: 'hi!' })
    }

    # try invalid host
    stub_request(:get, "https://api.telegram.org:443/bot#{token}/setWebhook?url=https://somehost.example.com/api/v1/channels_telegram_webhook/callback_token?bid=#{bot_id}")
      .to_return(status: 400, body: '{"ok":false,"error_code":400,"description":"Bad Request: bad webhook: getaddrinfo: Name or service not known"}', headers: {})

    Setting.set('fqdn', 'somehost.example.com')
    assert_raises(RuntimeError) {
      Telegram.create_or_update_channel(token, { group_id: group_id, welcome: 'hi!' })
    }

    # valid token, host and port
    stub_request(:get, "https://api.telegram.org:443/bot#{token}/setWebhook?url=https://example.com/api/v1/channels_telegram_webhook/callback_token?bid=#{bot_id}")
      .to_return(status: 200, body: '{"ok":true,"result":true,"description":"Webhook was set"}', headers: {})

    Setting.set('fqdn', 'example.com')
    channel = Telegram.create_or_update_channel(token, { group_id: group_id, welcome: 'hi!' })
    UserInfo.current_user_id = nil

    # start communication #1
    post '/api/v1/channels/telegram_webhook', read_messaage('personal1_message_start'), @headers
    assert_response(404)
    result = JSON.parse(@response.body)

    post '/api/v1/channels_telegram_webhook/not_existing', read_messaage('personal1_message_start'), @headers
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal('bot param missing', result['error'])

    callback_url = "/api/v1/channels_telegram_webhook/not_existing?bid=#{channel.options[:bot][:id]}"
    post callback_url, read_messaage('personal1_message_start'), @headers
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal('invalid callback token', result['error'])

    callback_url = "/api/v1/channels_telegram_webhook/#{channel.options[:callback_token]}?bid=#{channel.options[:bot][:id]}"
    post callback_url, read_messaage('personal1_message_start'), @headers
    assert_response(200)

    # send message1
    post callback_url, read_messaage('personal1_message_content1'), @headers
    assert_response(200)
    assert_equal(1, Ticket.count)
    ticket = Ticket.last
    assert_equal('Hello, I need your Help', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal(1, ticket.articles.count)
    assert_equal('Hello, I need your Help', ticket.articles.first.body)
    assert_equal('text/plain', ticket.articles.first.content_type)

    # send same message again, ignore it
    post callback_url, read_messaage('personal1_message_content1'), @headers
    assert_response(200)
    ticket = Ticket.last
    assert_equal('Hello, I need your Help', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal(1, ticket.articles.count)
    assert_equal('Hello, I need your Help', ticket.articles.first.body)
    assert_equal('text/plain', ticket.articles.first.content_type)

    # send message2
    post callback_url, read_messaage('personal1_message_content2'), @headers
    assert_response(200)
    ticket = Ticket.last
    assert_equal('Hello, I need your Help', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal(2, ticket.articles.count)
    assert_equal('Hello, I need your Help 2', ticket.articles.last.body)
    assert_equal('text/plain', ticket.articles.last.content_type)

    # send end message
    post callback_url, read_messaage('personal1_message_end'), @headers
    assert_response(200)
    ticket = Ticket.last
    assert_equal('Hello, I need your Help', ticket.title)
    assert_equal('closed', ticket.state.name)
    assert_equal(2, ticket.articles.count)
    assert_equal('Hello, I need your Help 2', ticket.articles.last.body)
    assert_equal('text/plain', ticket.articles.last.content_type)

    # start communication #2
    post callback_url, read_messaage('personal2_message_start'), @headers
    assert_response(200)

    # send message1
    post callback_url, read_messaage('personal2_message_content1'), @headers
    assert_response(200)
    assert_equal(2, Ticket.count)
    ticket = Ticket.last
    assert_equal('Can you help me with my feature?', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal(1, ticket.articles.count)
    assert_equal('Can you help me with my feature?', ticket.articles.first.body)
    assert_equal('text/plain', ticket.articles.first.content_type)

    # send message2
    post callback_url, read_messaage('personal2_message_content2'), @headers
    assert_response(200)
    assert_equal(2, Ticket.count)
    ticket = Ticket.last
    assert_equal('Can you help me with my feature?', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal(2, ticket.articles.count)
    assert_equal('Yes of course! <b>lalal</b>', ticket.articles.last.body)
    assert_equal('text/plain', ticket.articles.last.content_type)

    # start communication #3
    post callback_url, read_messaage('personal3_message_start'), @headers
    assert_response(200)

    # send message1
    post callback_url, read_messaage('personal3_message_content1'), @headers
    assert_response(200)
    assert_equal(3, Ticket.count)
    ticket = Ticket.last
    assert_equal('Can you help me with my feature?', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal(1, ticket.articles.count)
    assert_equal('Can you help me with my feature?', ticket.articles.last.body)
    assert_equal('text/plain', ticket.articles.last.content_type)

    # send message2
    stub_request(:get, "https://api.telegram.org/bot#{token}/getFile?file_id=ABC-123VabcOcv123w0ABHywrcPqfrbAYIABC")
      .to_return(status: 200, body: '{"result":{"file_size":123,"file_id":"ABC-123VabcOcv123w0ABHywrcPqfrbAYIABC","file_path":"abc123"}}', headers: {})
    stub_request(:get, "https://api.telegram.org/file/bot#{token}/abc123")
      .to_return(status: 200, body: 'ABC1', headers: {})

    post callback_url, read_messaage('personal3_message_content2'), @headers
    assert_response(200)
    assert_equal(3, Ticket.count)
    ticket = Ticket.last
    assert_equal('Can you help me with my feature?', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal(2, ticket.articles.count)
    assert_match(/<img style="width:360px;height:327px;"/i, ticket.articles.last.body)
    assert_equal('text/html', ticket.articles.last.content_type)

    # send message3
    stub_request(:get, "https://api.telegram.org/bot#{token}/getFile?file_id=AAQCABO0I4INAATATQAB5HWPq4XgxQACAg")
      .to_return(status: 200, body: '{"result":{"file_size":123,"file_id":"ABC-123AAQCABO0I4INAATATQAB5HWPq4XgxQACAg","file_path":"abc123"}}', headers: {})
    stub_request(:get, "https://api.telegram.org/file/bot#{token}/abc123")
      .to_return(status: 200, body: 'ABC2', headers: {})
    stub_request(:get, "https://api.telegram.org/bot#{token}/getFile?file_id=BQADAgADDgAD7x6ZSC_-1LMkOEmoAg")
      .to_return(status: 200, body: '{"result":{"file_size":123,"file_id":"ABC-123BQADAgADDgAD7x6ZSC_-1LMkOEmoAg","file_path":"abc123"}}', headers: {})

    post callback_url, read_messaage('personal3_message_content3'), @headers
    assert_response(200)
    assert_equal(3, Ticket.count)
    ticket = Ticket.last
    assert_equal('Can you help me with my feature?', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal(3, ticket.articles.count)
    assert_match(/<img style="width:200px;height:200px;"/i, ticket.articles.last.body)
    assert_equal('text/html', ticket.articles.last.content_type)
    assert_equal(1, ticket.articles.last.attachments.count)

    # update message1
    post callback_url, read_messaage('personal3_message_content4'), @headers
    assert_response(200)
    assert_equal(3, Ticket.count)
    ticket = Ticket.last
    assert_equal('Can you help me with my feature?', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal(3, ticket.articles.count)
    assert_match(/<img style="width:200px;height:200px;"/i, ticket.articles.last.body)
    assert_equal('text/html', ticket.articles.last.content_type)
    assert_equal(1, ticket.articles.last.attachments.count)

    assert_equal('UPDATE: 1231444', ticket.articles.first.body)
    assert_equal('text/plain', ticket.articles.first.content_type)

    # send voice5
    stub_request(:get, "https://api.telegram.org/bot#{token}/getFile?file_id=AwADAgADVQADCEIYSZwyOmSZK9iZAg")
      .to_return(status: 200, body: '{"result":{"file_size":123,"file_id":"ABC-123AwADAgADVQADCEIYSZwyOmSZK9iZAg","file_path":"abc123"}}', headers: {})

    post callback_url, read_messaage('personal3_message_content5'), @headers
    assert_response(200)
    assert_equal(3, Ticket.count)
    ticket = Ticket.last
    assert_equal('Can you help me with my feature?', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal(4, ticket.articles.count)
    assert_equal('text/html', ticket.articles.last.content_type)
    assert_equal(1, ticket.articles.last.attachments.count)

    # start communication #4 - with sticker
    stub_request(:get, "https://api.telegram.org/bot#{token}/getFile?file_id=AAQDABO3-e4qAASs6ZOjJUT7tQ4lAAIC")
      .to_return(status: 200, body: '{"result":{"file_size":123,"file_id":"ABC-123AAQDABO3-e4qAASs6ZOjJUT7tQ4lAAIC","file_path":"abc123"}}', headers: {})
    stub_request(:get, "https://api.telegram.org/bot#{token}/getFile?file_id=BQADAwAD0QIAAqbJWAAB8OkQqgtDQe0C")
      .to_return(status: 200, body: '{"result":{"file_size":123,"file_id":"ABC-123BQADAwAD0QIAAqbJWAAB8OkQqgtDQe0C","file_path":"abc123"}}', headers: {})

    post callback_url, read_messaage('personal4_message_content1'), @headers
    assert_response(200)
    assert_equal(4, Ticket.count)
    ticket = Ticket.last
    if Rails.application.config.db_4bytes_utf8
      assert_equal('💻', ticket.title)
    else
      assert_equal('', ticket.title)
    end
    assert_equal('new', ticket.state.name)
    assert_equal(1, ticket.articles.count)
    assert_match(/<img style="/i, ticket.articles.last.body)
    assert_equal('text/html', ticket.articles.last.content_type)
    assert_equal(1, ticket.articles.last.attachments.count)

    # start communication #5 - with photo
    stub_request(:get, "https://api.telegram.org/bot#{token}/getFile?file_id=AgADAgADwacxGxk5MUmim45lijOwsKk1Sw0ABNQoaI8BwR_z_2MFAAEC")
      .to_return(status: 200, body: '{"result":{"file_size":123,"file_id":"ABC-123AgADAgADwacxGxk5MUmim45lijOwsKk1Sw0ABNQoaI8BwR_z_2MFAAEC","file_path":"abc123"}}', headers: {})

    post callback_url, read_messaage('personal5_message_content1'), @headers
    assert_response(200)
    assert_equal(5, Ticket.count)
    ticket = Ticket.last
    assert_equal('-', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal(1, ticket.articles.count)
    assert_match(/<img style="/i, ticket.articles.last.body)
    assert_equal('text/html', ticket.articles.last.content_type)
    assert_equal(0, ticket.articles.last.attachments.count)

    post callback_url, read_messaage('personal5_message_content2'), @headers
    assert_response(200)
    assert_equal(5, Ticket.count)
    ticket = Ticket.last
    assert_equal('Hello, I need your Help', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal(2, ticket.articles.count)
    assert_match(/Hello, I need your Help/i, ticket.articles.last.body)
    assert_equal('text/plain', ticket.articles.last.content_type)
    assert_equal(0, ticket.articles.last.attachments.count)

  end

  def read_messaage(file)
    File.read("test/fixtures/telegram/#{file}.json")
  end
end
