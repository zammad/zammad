# encoding: utf-8
require 'test_helper'
require 'rexml/document'

class TelegramControllerTest < ActionDispatch::IntegrationTest
  setup do
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # configure telegram channel
    token = ENV['TELEGRAM_TOKEN']
    group_id = Group.find_by(name: 'Users').id
    #bot = Telegram.check_token(token)
    #Setting.set('http_type', 'http')
    Setting.set('http_type', 'https')
    Setting.set('fqdn', 'me.zammad.com')
    Channel.where(area: 'Telegram::Bot').destroy_all
    UserInfo.current_user_id = 1
    @channel = Telegram.create_or_update_channel(token, { group_id: group_id, welcome: 'hi!' })

    groups = Group.where(name: 'Users')
    roles  = Role.where(name: %w(Agent))
    agent  = User.create_or_update(
      login: 'telegram-agent@example.com',
      firstname: 'E',
      lastname: 'S',
      email: 'telegram-agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )
    UserInfo.current_user_id = nil

  end

  test 'basic call' do
    Ticket.destroy_all

    # start communication #1
    post '/api/v1/channels/telegram_webhook', read_messaage('personal1_message_start'), @headers
    assert_response(404)
    result = JSON.parse(@response.body)

    post '/api/v1/channels_telegram_webhook/not_existing', read_messaage('personal1_message_start'), @headers
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal('bot param missing', result['error'])

    callback_url = "/api/v1/channels_telegram_webhook/not_existing?bid=#{@channel.options[:bot][:id]}"
    post callback_url, read_messaage('personal1_message_start'), @headers
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal('invalid callback token', result['error'])

    callback_url = "/api/v1/channels_telegram_webhook/#{@channel.options[:callback_token]}?bid=#{@channel.options[:bot][:id]}"
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
    post callback_url, read_messaage('personal4_message_content1'), @headers
    assert_response(200)
    assert_equal(4, Ticket.count)
    ticket = Ticket.last
    assert_equal('💻', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal(1, ticket.articles.count)
    assert_match(/<img style="/i, ticket.articles.last.body)
    assert_equal('text/html', ticket.articles.last.content_type)
    assert_equal(1, ticket.articles.last.attachments.count)

    # start communication #5 - with photo
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
