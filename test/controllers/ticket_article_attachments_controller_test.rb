
require 'test_helper'

class TicketArticleAttachmentsControllerTest < ActionDispatch::IntegrationTest
  setup do

    # create agent
    roles  = Role.where(name: %w[Admin Agent])
    groups = Group.all

    UserInfo.current_user_id = 1
    @admin = User.create!(
      login: 'tickets-admin',
      firstname: 'Tickets',
      lastname: 'Admin',
      email: 'tickets-admin@example.com',
      password: 'adminpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create agent
    roles = Role.where(name: 'Agent')
    @agent = User.create!(
      login: 'tickets-agent@example.com',
      firstname: 'Tickets',
      lastname: 'Agent',
      email: 'tickets-agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create customer without org
    roles = Role.where(name: 'Customer')
    @customer_without_org = User.create!(
      login: 'tickets-customer1@example.com',
      firstname: 'Tickets',
      lastname: 'Customer1',
      email: 'tickets-customer1@example.com',
      password: 'customer1pw',
      active: true,
      roles: roles,
    )

  end

  test '01.01 test attachment urls' do
    ticket1 = Ticket.create(
      title: 'attachment test 1',
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    article1 = Ticket::Article.create(
      ticket_id: ticket1.id,
      from: 'some_customer_com-1@example.com',
      to: 'some_zammad_com-1@example.com',
      subject: 'attachment test 1-1',
      message_id: 'some@id_com_1',
      body: 'some message 123',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    store1 = Store.add(
      object: 'Ticket::Article',
      o_id: article1.id,
      data: 'some content',
      filename: 'some_file.txt',
      preferences: {
        'Content-Type' => 'text/plain',
      },
      created_by_id: 1,
    )
    article2 = Ticket::Article.create(
      ticket_id: ticket1.id,
      from: 'some_customer_com-1@example.com',
      to: 'some_zammad_com-1@example.com',
      subject: 'attachment test 1-2',
      message_id: 'some@id_com_1',
      body: 'some message 123',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    get "/api/v1/ticket_attachment/#{ticket1.id}/#{article1.id}/#{store1.id}", params: {}, headers: { 'Authorization' => credentials }
    assert_response(200)
    assert_equal('some content', @response.body)

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    get "/api/v1/ticket_attachment/#{ticket1.id}/#{article2.id}/#{store1.id}", params: {}, headers: { 'Authorization' => credentials }
    assert_response(401)
    assert_match(/401: Unauthorized/, @response.body)

    ticket2 = Ticket.create(
      title: 'attachment test 2',
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket1.merge_to(
      ticket_id: ticket2.id,
      user_id:   1,
    )

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    get "/api/v1/ticket_attachment/#{ticket2.id}/#{article1.id}/#{store1.id}", params: {}, headers: { 'Authorization' => credentials }
    assert_response(200)
    assert_equal('some content', @response.body)

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    get "/api/v1/ticket_attachment/#{ticket2.id}/#{article2.id}/#{store1.id}", params: {}, headers: { 'Authorization' => credentials }
    assert_response(401)
    assert_match(/401: Unauthorized/, @response.body)

    # allow access via merged ticket id also
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    get "/api/v1/ticket_attachment/#{ticket1.id}/#{article1.id}/#{store1.id}", params: {}, headers: { 'Authorization' => credentials }
    assert_response(200)
    assert_equal('some content', @response.body)

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    get "/api/v1/ticket_attachment/#{ticket1.id}/#{article2.id}/#{store1.id}", params: {}, headers: { 'Authorization' => credentials }
    assert_response(401)
    assert_match(/401: Unauthorized/, @response.body)

  end

  test '01.02 test attachments for split' do
    headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    email_file_path  = Rails.root.join('test', 'data', 'mail', 'mail024.box')
    email_raw_string = File.read(email_file_path)
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string)

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    get '/api/v1/ticket_split', params: { form_id: '1234-2', ticket_id: ticket_p.id, article_id: article_p.id }, headers: headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result['assets'])
    assert_equal(result['attachments'].class, Array)
    assert_equal(result['attachments'].count, 1)
    assert_equal(result['attachments'][0]['filename'], 'rulesets-report.csv')

  end

  test '01.03 test attachments for forward' do
    headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    email_file_path  = Rails.root.join('test', 'data', 'mail', 'mail008.box')
    email_raw_string = File.read(email_file_path)
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string)

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    post "/api/v1/ticket_attachment_upload_clone_by_article/#{article_p.id}", params: {}, headers: headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert(result['error'], 'Need form_id to attach attachments to new form')

    post "/api/v1/ticket_attachment_upload_clone_by_article/#{article_p.id}", params: { form_id: '1234-1' }.to_json, headers: headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result['attachments'].class, Array)
    assert(result['attachments'].blank?)

    email_file_path  = Rails.root.join('test', 'data', 'mail', 'mail024.box')
    email_raw_string = File.read(email_file_path)
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string)

    post "/api/v1/ticket_attachment_upload_clone_by_article/#{article_p.id}", params: { form_id: '1234-2' }.to_json, headers: headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result['attachments'].class, Array)
    assert_equal(result['attachments'].count, 1)
    assert_equal(result['attachments'][0]['filename'], 'rulesets-report.csv')

    post "/api/v1/ticket_attachment_upload_clone_by_article/#{article_p.id}", params: { form_id: '1234-2' }.to_json, headers: headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result['attachments'].class, Array)
    assert(result['attachments'].blank?)
  end

end
