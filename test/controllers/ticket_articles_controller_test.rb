
require 'test_helper'

class TicketArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

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

  test '01.01 ticket create with agent and articles' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')

    params = {
      title: 'a new ticket #1',
      group: 'Users',
      customer_id: @customer_without_org.id,
      article: {
        body: 'some body',
      }
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)

    params = {
      ticket_id: result['id'],
      content_type: 'text/plain', # or text/html
      body: 'some body',
      type: 'note',
    }
    post '/api/v1/ticket_articles', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_nil(result['subject'])
    assert_equal('some body', result['body'])
    assert_equal('text/plain', result['content_type'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])

    ticket = Ticket.find(result['ticket_id'])
    assert_equal(2, ticket.articles.count)
    assert_equal(0, ticket.articles[0].attachments.count)
    assert_equal(0, ticket.articles[1].attachments.count)

    params = {
      ticket_id: result['ticket_id'],
      content_type: 'text/html', # or text/html
      body: 'some body <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA
AAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO
9TXL0Y4OHwAAAABJRU5ErkJggg==" alt="Red dot" />',
      type: 'note',
    }
    post '/api/v1/ticket_articles', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_nil(result['subject'])
    assert_no_match(/some body <img src="cid:.+?/, result['body'])
    assert_match(%r{some body <img src="/api/v1/ticket_attachment/.+?" alt="Red dot"}, result['body'])
    assert_equal('text/html', result['content_type'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])

    assert_equal(3, ticket.articles.count)
    assert_equal(0, ticket.articles[0].attachments.count)
    assert_equal(0, ticket.articles[1].attachments.count)
    assert_equal(1, ticket.articles[2].attachments.count)
    assert(ticket.articles[2].attachments[0]['id'])
    assert_equal('image1.png', ticket.articles[2].attachments[0]['filename'])
    assert_equal('21', ticket.articles[2].attachments[0]['size'])
    assert_equal('image/png', ticket.articles[2].attachments[0]['preferences']['Mime-Type'])
    assert_equal('inline', ticket.articles[2].attachments[0]['preferences']['Content-Disposition'])
    assert_match(/@zammad.example.com/, ticket.articles[2].attachments[0]['preferences']['Content-ID'])

    params = {
      ticket_id: result['ticket_id'],
      content_type: 'text/html', # or text/html
      body: 'some body',
      type: 'note',
      attachments: [
        'filename' => 'some_file.txt',
        'data' => 'dGVzdCAxMjM=',
        'mime-type' => 'text/plain',
      ],
    }
    post '/api/v1/ticket_articles', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_nil(result['subject'])
    assert_equal('some body', result['body'])
    assert_equal('text/html', result['content_type'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])

    assert_equal(4, ticket.articles.count)
    assert_equal(0, ticket.articles[0].attachments.count)
    assert_equal(0, ticket.articles[1].attachments.count)
    assert_equal(1, ticket.articles[2].attachments.count)
    assert_equal(1, ticket.articles[3].attachments.count)

    get "/api/v1/ticket_articles/#{result['id']}?expand=true", params: {}.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(1, result['attachments'].count)
    assert(result['attachments'][0]['id'])
    assert_equal('some_file.txt', result['attachments'][0]['filename'])
    assert_equal('8', result['attachments'][0]['size'])
    assert_equal('text/plain', result['attachments'][0]['preferences']['Mime-Type'])
  end

  test '02.01 ticket create with customer and articles' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-customer1@example.com', 'customer1pw')

    params = {
      title: 'a new ticket #2',
      group: 'Users',
      article: {
        body: 'some body',
      }
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)

    params = {
      ticket_id: result['id'],
      content_type: 'text/plain', # or text/html
      body: 'some body',
      type: 'note',
    }
    post '/api/v1/ticket_articles', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_nil(result['subject'])
    assert_equal('some body', result['body'])
    assert_equal('text/plain', result['content_type'])
    assert_equal(@customer_without_org.id, result['updated_by_id'])
    assert_equal(@customer_without_org.id, result['created_by_id'])

    ticket = Ticket.find(result['ticket_id'])
    assert_equal(2, ticket.articles.count)
    assert_equal('Customer', ticket.articles[1].sender.name)
    assert_equal(0, ticket.articles[0].attachments.count)
    assert_equal(0, ticket.articles[1].attachments.count)

    params = {
      ticket_id: result['ticket_id'],
      content_type: 'text/plain', # or text/html
      body: 'some body',
      sender: 'Agent',
      type: 'note',
    }
    post '/api/v1/ticket_articles', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_nil(result['subject'])
    assert_equal('some body', result['body'])
    assert_equal('text/plain', result['content_type'])
    assert_equal(@customer_without_org.id, result['updated_by_id'])
    assert_equal(@customer_without_org.id, result['created_by_id'])

    ticket = Ticket.find(result['ticket_id'])
    assert_equal(3, ticket.articles.count)
    assert_equal('Customer', ticket.articles[2].sender.name)
    assert_equal(false, ticket.articles[2].internal)
    assert_equal(0, ticket.articles[0].attachments.count)
    assert_equal(0, ticket.articles[1].attachments.count)
    assert_equal(0, ticket.articles[2].attachments.count)

    params = {
      ticket_id: result['ticket_id'],
      content_type: 'text/plain', # or text/html
      body: 'some body 2',
      sender: 'Agent',
      type: 'note',
      internal: true,
    }
    post '/api/v1/ticket_articles', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_nil(result['subject'])
    assert_equal('some body 2', result['body'])
    assert_equal('text/plain', result['content_type'])
    assert_equal(@customer_without_org.id, result['updated_by_id'])
    assert_equal(@customer_without_org.id, result['created_by_id'])

    ticket = Ticket.find(result['ticket_id'])
    assert_equal(4, ticket.articles.count)
    assert_equal('Customer', ticket.articles[3].sender.name)
    assert_equal(false, ticket.articles[3].internal)
    assert_equal(0, ticket.articles[0].attachments.count)
    assert_equal(0, ticket.articles[1].attachments.count)
    assert_equal(0, ticket.articles[2].attachments.count)
    assert_equal(0, ticket.articles[3].attachments.count)

    # add internal article
    article = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message 123',
      internal: true,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(5, ticket.articles.count)
    assert_equal('Agent', ticket.articles[4].sender.name)
    assert_equal(1, ticket.articles[4].updated_by_id)
    assert_equal(1, ticket.articles[4].created_by_id)
    assert_equal(0, ticket.articles[0].attachments.count)
    assert_equal(0, ticket.articles[1].attachments.count)
    assert_equal(0, ticket.articles[2].attachments.count)
    assert_equal(0, ticket.articles[3].attachments.count)
    assert_equal(0, ticket.articles[4].attachments.count)

    get "/api/v1/ticket_articles/#{article.id}", params: {}.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized', result['error'])

    put "/api/v1/ticket_articles/#{article.id}", params: { internal: false }.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized', result['error'])

  end

  test '03.01 create phone ticket for customer and expected origin_by_id' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')

    params = {
      title: 'a new ticket #1',
      group: 'Users',
      customer_id: @customer_without_org.id,
      article: {
        body: 'some body',
        sender: 'Customer',
        type: 'phone',
      }
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    article = Ticket::Article.find_by(ticket_id: result['id'])
    assert_equal(@customer_without_org.id, article.origin_by_id)
    assert_equal('Tickets Customer1 <tickets-customer1@example.com>', article.from)
  end

  test '03.02 create phone ticket by customer and manipulate origin_by_id' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-customer1@example.com', 'customer1pw')

    params = {
      title: 'a new ticket #1',
      group: 'Users',
      customer_id: @customer_without_org.id,
      article: {
        body: 'some body',
        sender: 'Customer',
        type: 'phone',
        origin_by_id: 1,
      }
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    article = Ticket::Article.find_by(ticket_id: result['id'])
    assert_equal(@customer_without_org.id, article.origin_by_id)
  end

  test '04.01 ticket split with html - check attachments' do
    ticket = Ticket.create!(
      title: 'some title',
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @agent.id,
      created_by_id: @agent.id,
    )
    article = Ticket::Article.create!(
      type: Ticket::Article::Type.lookup(name: 'note'),
      sender: Ticket::Article::Sender.lookup(name: 'Customer'),
      from: 'sender',
      subject: 'subject',
      body: '<b>test</b> <img src="cid:15.274327094.140938@ZAMMAD.example.com"/> test <img src="cid:15.274327094.140938.3@ZAMMAD.example.com"/>',
      content_type: 'text/html',
      ticket_id: ticket.id,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Store.add(
      object: 'Ticket::Article',
      o_id: article.id,
      data: 'content_file1_normally_should_be_an_image',
      filename: 'some_file1.jpg',
      preferences: {
        'Content-Type'        => 'image/jpeg',
        'Mime-Type'           => 'image/jpeg',
        'Content-ID'          => '15.274327094.140938@zammad.example.com',
        'Content-Disposition' => 'inline',
      },
      created_by_id: 1,
    )
    Store.add(
      object: 'Ticket::Article',
      o_id: article.id,
      data: 'content_file2_normally_should_be_an_image',
      filename: 'some_file2.jpg',
      preferences: {
        'Content-Type'        => 'image/jpeg',
        'Mime-Type'           => 'image/jpeg',
        'Content-ID'          => '15.274327094.140938.2@zammad.example.com',
        'Content-Disposition' => 'inline',
      },
      created_by_id: 1,
    )
    Store.add(
      object: 'Ticket::Article',
      o_id: article.id,
      data: 'content_file3_normally_should_be_an_image',
      filename: 'some_file3.jpg',
      preferences: {
        'Content-Type'        => 'image/jpeg',
        'Mime-Type'           => 'image/jpeg',
        'Content-ID'          => '15.274327094.140938.3@zammad.example.com',
      },
      created_by_id: 1,
    )
    Store.add(
      object: 'Ticket::Article',
      o_id: article.id,
      data: 'content_file4_normally_should_be_an_image',
      filename: 'some_file4.jpg',
      preferences: {
        'Content-Type'        => 'image/jpeg',
        'Mime-Type'           => 'image/jpeg',
        'Content-ID'          => '15.274327094.140938.4@zammad.example.com',
      },
      created_by_id: 1,
    )
    Store.add(
      object: 'Ticket::Article',
      o_id: article.id,
      data: 'content_file1_normally_should_be_an_pdf',
      filename: 'Rechnung_RE-2018-200.pdf',
      preferences: {
        'Content-Type'        => 'application/octet-stream; name="Rechnung_RE-2018-200.pdf"',
        'Mime-Type'           => 'application/octet-stream',
        'Content-ID'          => '8AB0BEC88984EE4EBEF643C79C8E0346@zammad.example.com',
        'Content-Description' => 'Rechnung_RE-2018-200.pdf',
        'Content-Disposition' => 'attachment',
      },
      created_by_id: 1,
    )

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')

    params = {
      form_id: 'new_form_id123',
    }
    post "/api/v1/ticket_attachment_upload_clone_by_article/#{article.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['attachments'])
    assert_equal(result['attachments'].count, 3)

    post "/api/v1/ticket_attachment_upload_clone_by_article/#{article.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['attachments'])
    assert_equal(result['attachments'].count, 0)
  end

  test '04.02 ticket split with plain - check attachments' do
    ticket = Ticket.create!(
      title: 'some title',
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @agent.id,
      created_by_id: @agent.id,
    )
    article = Ticket::Article.create!(
      type: Ticket::Article::Type.lookup(name: 'note'),
      sender: Ticket::Article::Sender.lookup(name: 'Customer'),
      from: 'sender',
      subject: 'subject',
      body: '<b>test</b> <img src="cid:15.274327094.140938@zammad.example.com"/>',
      content_type: 'text/plain',
      ticket_id: ticket.id,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Store.add(
      object: 'Ticket::Article',
      o_id: article.id,
      data: 'content_file1_normally_should_be_an_image',
      filename: 'some_file1.jpg',
      preferences: {
        'Content-Type'        => 'image/jpeg',
        'Mime-Type'           => 'image/jpeg',
        'Content-ID'          => '15.274327094.140938@zammad.example.com',
        'Content-Disposition' => 'inline',
      },
      created_by_id: 1,
    )
    Store.add(
      object: 'Ticket::Article',
      o_id: article.id,
      data: 'content_file1_normally_should_be_an_image',
      filename: 'some_file2.jpg',
      preferences: {
        'Content-Type'        => 'image/jpeg',
        'Mime-Type'           => 'image/jpeg',
        'Content-ID'          => '15.274327094.140938.2@zammad.example.com',
        'Content-Disposition' => 'inline',
      },
      created_by_id: 1,
    )
    Store.add(
      object: 'Ticket::Article',
      o_id: article.id,
      data: 'content_file1_normally_should_be_an_pdf',
      filename: 'Rechnung_RE-2018-200.pdf',
      preferences: {
        'Content-Type'        => 'application/octet-stream; name="Rechnung_RE-2018-200.pdf"',
        'Mime-Type'           => 'application/octet-stream',
        'Content-ID'          => '8AB0BEC88984EE4EBEF643C79C8E0346@zammad.example.com',
        'Content-Description' => 'Rechnung_RE-2018-200.pdf',
        'Content-Disposition' => 'attachment',
      },
      created_by_id: 1,
    )

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')

    params = {
      form_id: 'new_form_id123',
    }
    post "/api/v1/ticket_attachment_upload_clone_by_article/#{article.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['attachments'])
    assert_equal(result['attachments'].count, 3)

    post "/api/v1/ticket_attachment_upload_clone_by_article/#{article.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['attachments'])
    assert_equal(result['attachments'].count, 0)

  end

end
