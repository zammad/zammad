require 'test_helper'
require 'rexml/document'
require 'webmock/minitest'

class TwilioSmsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }
  end

  test 'basic call' do

    # configure twilio channel
    bot_id = 123_456_789
    group_id = Group.find_by(name: 'Users').id

    UserInfo.current_user_id = 1
    channel = Channel.create!(
      area: 'Sms::Account',
      options: {
        adapter: 'sms/twilio',
        webhook_token: 'f409460e50f76d331fdac8ba7b7963b6',
        account_id: '111',
        token: '223',
        sender: '333',
      },
      group_id: nil,
      active: true,
    )

    # create agent
    agent = User.create!(
      login: 'tickets-agent@example.com',
      firstname: 'Tickets',
      lastname: 'Agent',
      email: 'tickets-agent@example.com',
      password: 'agentpw',
      active: true,
      roles: Role.where(name: 'Agent'),
      groups: Group.all,
    )

    # process inbound sms
    post '/api/v1/sms_webhook', params: read_messaage('inbound_sms1'), headers: @headers
    assert_response(404)
    result = JSON.parse(@response.body)

    post '/api/v1/sms_webhook/not_existing', params: read_messaage('inbound_sms1'), headers: @headers
    assert_response(404)
    result = JSON.parse(@response.body)

    post '/api/v1/sms_webhook/f409460e50f76d331fdac8ba7b7963b6', params: read_messaage('inbound_sms1'), headers: @headers
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(result['error'], 'Can\'t use Channel::Driver::Sms::Twilio: #<Exceptions::UnprocessableEntity: Group needed in channel definition!>')

    channel.group_id = Group.first.id
    channel.save!

    post '/api/v1/sms_webhook/f409460e50f76d331fdac8ba7b7963b6', params: read_messaage('inbound_sms1'), headers: @headers
    assert_response(200)
    response = REXML::Document.new(@response.body)
    assert_equal(response.elements.count, 1)

    ticket = Ticket.last
    article = Ticket::Article.last
    customer = User.last
    assert_equal(1, ticket.articles.count)
    assert_equal('Ldfhxhcuffufuf. Fifififig.  Fifififiif F...', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal(group_id, ticket.group_id)
    assert_equal(customer.id, ticket.customer_id)
    assert_equal(customer.id, ticket.created_by_id)
    assert_equal('+491710000000', article.from)
    assert_equal('+4915700000000', article.to)
    assert_nil(article.cc)
    assert_nil(article.subject)
    assert_equal('Ldfhxhcuffufuf. Fifififig.  Fifififiif Fifififiif Fifififiif Fifififiif Fifififiif', article.body)
    assert_equal(customer.id, article.created_by_id)
    assert_equal('Customer', article.sender.name)
    assert_equal('sms', article.type.name)

    post '/api/v1/sms_webhook/f409460e50f76d331fdac8ba7b7963b6', params: read_messaage('inbound_sms2'), headers: @headers
    assert_response(200)
    response = REXML::Document.new(@response.body)
    assert_equal(response.elements.count, 1)

    ticket.reload
    assert_equal(2, ticket.articles.count)
    assert_equal('new', ticket.state.name)

    article = Ticket::Article.last
    assert_equal('+491710000000', article.from)
    assert_equal('+4915700000000', article.to)
    assert_nil(article.cc)
    assert_nil(article.subject)
    assert_equal('Follow up', article.body)
    assert_equal('Customer', article.sender.name)
    assert_equal('sms', article.type.name)
    assert_equal(customer.id, article.created_by_id)

    # check duplicate callbacks
    post '/api/v1/sms_webhook/f409460e50f76d331fdac8ba7b7963b6', params: read_messaage('inbound_sms2'), headers: @headers
    assert_response(200)
    response = REXML::Document.new(@response.body)
    assert_equal(response.elements.count, 1)

    ticket.reload
    assert_equal(2, ticket.articles.count)
    assert_equal('new', ticket.state.name)
    assert_equal(Ticket::Article.last.id, article.id)

    # new ticket need to be create
    ticket.state = Ticket::State.find_by(name: 'closed')
    ticket.save!

    post '/api/v1/sms_webhook/f409460e50f76d331fdac8ba7b7963b6', params: read_messaage('inbound_sms3'), headers: @headers
    assert_response(200)
    response = REXML::Document.new(@response.body)
    assert_equal(response.elements.count, 1)

    ticket.reload
    assert_equal(2, ticket.articles.count)
    assert_not_equal(Ticket.last.id, ticket.id)
    assert_equal('closed', ticket.state.name)

    ticket = Ticket.last
    article = Ticket::Article.last
    customer = User.last
    assert_equal(1, ticket.articles.count)
    assert_equal('new 2', ticket.title)
    assert_equal(group_id, ticket.group_id)
    assert_equal(customer.id, ticket.customer_id)
    assert_equal(customer.id, ticket.created_by_id)
    assert_equal('+491710000000', article.from)
    assert_equal('+4915700000000', article.to)
    assert_nil(article.cc)
    assert_nil(article.subject)
    assert_equal('new 2', article.body)
    assert_equal(customer.id, article.created_by_id)
    assert_equal('Customer', article.sender.name)
    assert_equal('sms', article.type.name)

    # reply by agent
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      ticket_id: ticket.id,
      body: 'some test',
      type: 'sms',
    }
    post '/api/v1/ticket_articles', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_nil(result['subject'])
    assert_equal('some test', result['body'])
    assert_equal('text/plain', result['content_type'])
    assert_equal(agent.id, result['updated_by_id'])
    assert_equal(agent.id, result['created_by_id'])

    stub_request(:post, 'https://api.twilio.com/2010-04-01/Accounts/111/Messages.json')
      .with(
        body: {
          'Body' => 'some test',
          'From' => '333',
          'To' => nil,
        },
        headers: {
          'Accept' => 'application/json',
          'Accept-Charset' => 'utf-8',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => 'Basic MTExOjIyMw==',
          'Content-Type' => 'application/x-www-form-urlencoded',
          'User-Agent' => 'twilio-ruby/5.10.2 (ruby/x86_64-darwin16 2.4.4-p296)'
        }
      ).to_return(status: 200, body: '', headers: {})

    assert_nil(article.preferences[:delivery_retry])
    assert_nil(article.preferences[:delivery_status])

    Observer::Transaction.commit
    Scheduler.worker(true)

    article = Ticket::Article.find(result['id'])
    assert_equal(1, article.preferences[:delivery_retry])
    assert_equal('success', article.preferences[:delivery_status])

  end

  test 'customer based on already existing mobile attibute' do

    customer = User.create!(
      firstname: '',
      lastname: '',
      email: 'me@example.com',
      mobile: '01710000000',
      note: '',
      updated_by_id: 1,
      created_by_id: 1,
    )
    Observer::Transaction.commit
    Scheduler.worker(true)

    # configure twilio channel
    bot_id = 123_456_789
    group_id = Group.find_by(name: 'Users').id

    UserInfo.current_user_id = 1
    channel = Channel.create!(
      area: 'Sms::Account',
      options: {
        adapter: 'sms/twilio',
        webhook_token: 'f409460e50f76d331fdac8ba7b7963b6',
        account_id: '111',
        token: '223',
        sender: '333',
      },
      group_id: group_id,
      active: true,
    )

    post '/api/v1/sms_webhook/f409460e50f76d331fdac8ba7b7963b6', params: read_messaage('inbound_sms1'), headers: @headers
    assert_response(200)
    response = REXML::Document.new(@response.body)
    assert_equal(response.elements.count, 1)

    assert_equal(User.last.id, customer.id)
  end

  def read_messaage(file)
    File.read(Rails.root.join('test', 'data', 'twilio', "#{file}.json"))
  end
end
