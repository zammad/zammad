# encoding: utf-8
require 'test_helper'

class ChannelsControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # create agent
    roles  = Role.where(name: %w(Admin Agent))
    groups = Group.all

    UserInfo.current_user_id = 1
    @admin = User.create_or_update(
      login: 'packages-admin',
      firstname: 'Packages',
      lastname: 'Admin',
      email: 'packages-admin@example.com',
      password: 'adminpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create agent
    roles = Role.where(name: 'Agent')
    @agent = User.create_or_update(
      login: 'packages-agent@example.com',
      firstname: 'Rest',
      lastname: 'Agent',
      email: 'packages-agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create customer without org
    roles = Role.where(name: 'Customer')
    @customer_without_org = User.create_or_update(
      login: 'packages-customer1@example.com',
      firstname: 'Packages',
      lastname: 'Customer1',
      email: 'packages-customer1@example.com',
      password: 'customer1pw',
      active: true,
      roles: roles,
    )

  end

  test '01 telegram_webhook creates ticket' do
    json = File.read('test/fixtures/telegram/personal_message_content.json')
    post '/api/v1/channels/telegram_webhook', json, @headers
    puts JSON.parse(@response.body).inspect

    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal({ 'ok' => 'ok' }, result)
  end

  test '0x telegram_webhook with existing ticket adds ticket_article'
  test '0x telegram_webhook sends welcome message on /start'
  test '0x telegram_webhook closes the ticket on /stop'
end
