# encoding: utf-8
require 'test_helper'

class TicketsControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # create agent
    roles  = Role.where(name: %w(Admin Agent))
    groups = Group.all

    UserInfo.current_user_id = 1
    @admin = User.create_or_update(
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
    @agent = User.create_or_update(
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
    @customer_without_org = User.create_or_update(
      login: 'tickets-customer1@example.com',
      firstname: 'Tickets',
      lastname: 'Customer1',
      email: 'tickets-customer1@example.com',
      password: 'customer1pw',
      active: true,
      roles: roles,
    )

  end

  test '01.01 ticket create with agent - missing group' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #1',
      article: {
        content_type: 'text/plain', # or text/html
        body: 'some body',
        sender: 'Customer',
        type: 'note',
      },
    }
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Group can\'t be blank', result['error_human'])
  end

  test '01.02 ticket create with agent - wrong group' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #2',
      group: 'not_existing',
      article: {
        content_type: 'text/plain', # or text/html
        body: 'some body',
        sender: 'Customer',
        type: 'note',
      },
    }
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('No lookup value found for \'group\': "not_existing"', result['error'])
  end

  test '01.03 ticket create with agent - missing article.body' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #3',
      group: 'Users',
      priority: '2 normal',
      state: 'new',
      customer_id: @customer_without_org.id,
      article: {},
    }
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Need at least article: { body: "some text" }', result['error'])
  end

  test '01.03 ticket create with agent - minimal article' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #3',
      group: 'Users',
      priority: '2 normal',
      state: 'new',
      customer_id: @customer_without_org.id,
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #3', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
  end

  test '01.04 ticket create with agent - wrong owner_id - 0' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #4',
      group: 'Users',
      priority: '2 normal',
      owner_id: 0,
      state: 'new',
      customer_id: @customer_without_org.id,
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Invalid value for param \'owner_id\': 0', result['error'])
  end

  test '01.05 ticket create with agent - wrong owner_id - ""' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #5',
      group: 'Users',
      priority: '2 normal',
      owner_id: '',
      state: 'new',
      customer_id: @customer_without_org.id,
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    #assert_response(422)
    #result = JSON.parse(@response.body)
    #assert_equal(Hash, result.class)
    #assert_equal('Invalid value for param \'owner_id\': ""', result['error'])
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #5', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
  end

  test '01.06 ticket create with agent - wrong owner_id - 99999' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #6',
      group: 'Users',
      priority: '2 normal',
      owner_id: 99_999,
      state: 'new',
      customer_id: @customer_without_org.id,
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Invalid value for param \'owner_id\': 99999', result['error'])
  end

  test '01.07 ticket create with agent - wrong owner_id - nil' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #7',
      group: 'Users',
      priority: '2 normal',
      owner_id: nil,
      state: 'new',
      customer_id: @customer_without_org.id,
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #7', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
  end

  test '01.08 ticket create with agent - minimal article with guess customer' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #8',
      group: 'Users',
      priority: '2 normal',
      state: 'new',
      customer_id: 'guess:some_new_customer@example.com',
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #8', result['title'])
    assert_equal(User.lookup(email: 'some_new_customer@example.com').id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
  end

  test '01.09 ticket create with agent - minimal article with guess customer' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #9',
      group: 'Users',
      customer_id: 'guess:some_new_customer@example.com',
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #9', result['title'])
    assert_equal(User.lookup(email: 'some_new_customer@example.com').id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
  end

  test '01.10 ticket create with agent - minimal article with missing body - with customer' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #10',
      group: 'Users',
      customer_id: @customer_without_org.id,
      article: {
        subject: 'some test 123',
      },
    }
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Need at least article: { body: "some text" }', result['error'])
  end

  test '01.11 ticket create with agent - minimal article and attachment with customer' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #11',
      group: 'Users',
      customer_id: @customer_without_org.id,
      article: {
        subject: 'some test 123',
        body: 'some test 123',
        attachments: [
          'filename' => 'some_file.txt',
          'data' => 'dGVzdCAxMjM=',
          'mime-type' => 'text/plain',
        ],
      },
    }
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #11', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])

    ticket = Ticket.find(result['id'])
    assert_equal(1, ticket.articles.count)
    assert_equal(1, ticket.articles.first.attachments.count)
    file = ticket.articles.first.attachments.first
    assert_equal('test 123', file.content)
    assert_equal('some_file.txt', file.filename)
    assert_equal('text/plain', file.preferences['Mime-Type'])
    assert_not(file.preferences['Content-ID'])
  end

  test '01.12 ticket create with agent - minimal article and attachment with customer' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #12',
      group: 'Users',
      customer_id: @customer_without_org.id,
      article: {
        subject: 'some test 123',
        body: 'some test 123',
        attachments: [
          {
            'filename' => 'some_file1.txt',
            'data' => 'dGVzdCAxMjM=',
            'mime-type' => 'text/plain',
          },
          {
            'filename' => 'some_file2.txt',
            'data' => 'w6TDtsO8w58=',
            'mime-type' => 'text/plain',
          },
        ],
      },
    }
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #12', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])

    ticket = Ticket.find(result['id'])
    assert_equal(1, ticket.articles.count)
    assert_equal(2, ticket.articles.first.attachments.count)
    file = ticket.articles.first.attachments.first
    assert_equal('test 123', file.content)
    assert_equal('some_file1.txt', file.filename)
    assert_equal('text/plain', file.preferences['Mime-Type'])
    assert_not(file.preferences['Content-ID'])
  end

  test '01.13 ticket create with agent - minimal article and attachment missing mine-type with customer' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #13',
      group: 'Users',
      customer_id: @customer_without_org.id,
      article: {
        subject: 'some test 123',
        body: 'some test 123',
        attachments: [
          'filename' => 'some_file.txt',
          'data' => 'ABC_INVALID_BASE64',
          'mime-type' => 'text/plain',
        ],
      },
    }
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Invalid base64 for attachment with index \'0\'', result['error'])
  end

  test '01.14 ticket create with agent - minimal article and attachment invalid base64 with customer' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #14',
      group: 'Users',
      customer_id: @customer_without_org.id,
      article: {
        subject: 'some test 123',
        body: 'some test 123',
        attachments: [
          'filename' => 'some_file.txt',
          'data' => 'dGVzdCAxMjM=',
        ],
      },
    }
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Attachment needs \'mime-type\' param for attachment with index \'0\'', result['error'])
  end

  test '01.15 ticket create with agent - minimal article and inline attachments with customer' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #15',
      group: 'Users',
      customer_id: @customer_without_org.id,
      article: {
        content_type: 'text/html',
        subject: 'some test 123',
        body: 'some test 123 <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA
AAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO
9TXL0Y4OHwAAAABJRU5ErkJggg==" alt="Red dot" /> <img src="data:image/jpeg;base64,/9j/4QAYRXhpZgAASUkqAAgAAAAAAAAAAAAAAP/sABFEdWNreQABAAQAAAAJAAD/4QMtaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLwA8P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIenJlU3pOVGN6a2M5ZCI/PiA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJBZG9iZSBYTVAgQ29yZSA1LjMtYzAxMSA2Ni4xNDU2NjEsIDIwMTIvMDIvMDYtMTQ6NTY6MjcgICAgICAgICI+IDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bXA6Q3JlYXRvclRvb2w9IkFkb2JlIFBob3Rvc2hvcCBDUzYgKE1hY2ludG9zaCkiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6QzJCOTE2NzlGQUEwMTFFNjg0M0NGQjU0OUU4MTFEOEIiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6QzJCOTE2N0FGQUEwMTFFNjg0M0NGQjU0OUU4MTFEOEIiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDpDMkI5MTY3N0ZBQTAxMUU2ODQzQ0ZCNTQ5RTgxMUQ4QiIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDpDMkI5MTY3OEZBQTAxMUU2ODQzQ0ZCNTQ5RTgxMUQ4QiIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/Pv/uAA5BZG9iZQBkwAAAAAH/2wCEABQRERoTGioZGSo1KCEoNTEpKCgpMUE4ODg4OEFEREREREREREREREREREREREREREREREREREREREREREREREQBFhoaIh0iKRoaKTkpIik5RDktLTlEREREOERERERERERERERERERERERERERERERERERERERERERERERERERERP/AABEIABAADAMBIgACEQEDEQH/xABbAAEBAAAAAAAAAAAAAAAAAAAEBQEBAQAAAAAAAAAAAAAAAAAABAUQAAEEAgMAAAAAAAAAAAAAAAABAhIDESIxBAURAAICAwAAAAAAAAAAAAAAAAESABNRoQP/2gAMAwEAAhEDEQA/AJDq1rfF3Imeg/1+lFy2oR564DKWWWbweV+Buf/Z">',
      },
    }

    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #15', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])

    ticket = Ticket.find(result['id'])
    assert_equal(1, ticket.articles.count)
    assert_equal(2, ticket.articles.first.attachments.count)
    file = ticket.articles.first.attachments[0]
    assert_equal('d3c1e09bdefb92b6a06b791a24ca9599', Digest::MD5.hexdigest(file.content))
    assert_match(/#{ticket.id}\..+?@zammad.example.com/, file.filename)
    assert_equal('image/png', file.preferences['Mime-Type'])
    assert(file.preferences['Content-ID'])
    file = ticket.articles.first.attachments[1]
    assert_equal('006a2ca3793b550c8fe444acdeb39252', Digest::MD5.hexdigest(file.content))
    assert_match(/#{ticket.id}\..+?@zammad.example.com/, file.filename)
    assert_equal('image/jpeg', file.preferences['Mime-Type'])
    assert(file.preferences['Content-ID'])
  end

  test '01.16 ticket create with agent - minimal article and inline attachments with customer' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #16',
      group: 'Users',
      customer_id: @customer_without_org.id,
      article: {
        content_type: 'text/html',
        subject: 'some test 123',
        body: 'some test 123 <img src="data:image/jpeg;base64,/9j/4QAYRXhpZgAASUkqAAgAAAAAAAAAAAAAAP/sABFEdWNreQABAAQAAAAJAAD/4QMtaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLwA8P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIenJlU3pOVGN6a2M5ZCI/PiA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJBZG9iZSBYTVAgQ29yZSA1LjMtYzAxMSA2Ni4xNDU2NjEsIDIwMTIvMDIvMDYtMTQ6NTY6MjcgICAgICAgICI+IDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bXA6Q3JlYXRvclRvb2w9IkFkb2JlIFBob3Rvc2hvcCBDUzYgKE1hY2ludG9zaCkiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6QzJCOTE2NzlGQUEwMTFFNjg0M0NGQjU0OUU4MTFEOEIiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6QzJCOTE2N0FGQUEwMTFFNjg0M0NGQjU0OUU4MTFEOEIiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDpDMkI5MTY3N0ZBQTAxMUU2ODQzQ0ZCNTQ5RTgxMUQ4QiIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDpDMkI5MTY3OEZBQTAxMUU2ODQzQ0ZCNTQ5RTgxMUQ4QiIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/Pv/uAA5BZG9iZQBkwAAAAAH/2wCEABQRERoTGioZGSo1KCEoNTEpKCgpMUE4ODg4OEFEREREREREREREREREREREREREREREREREREREREREREREREQBFhoaIh0iKRoaKTkpIik5RDktLTlEREREOERERERERERERERERERERERERERERERERERERERERERERERERERERP/AABEIABAADAMBIgACEQEDEQH/xABbAAEBAAAAAAAAAAAAAAAAAAAEBQEBAQAAAAAAAAAAAAAAAAAABAUQAAEEAgMAAAAAAAAAAAAAAAABAhIDESIxBAURAAICAwAAAAAAAAAAAAAAAAESABNRoQP/2gAMAwEAAhEDEQA/AJDq1rfF3Imeg/1+lFy2oR564DKWWWbweV+Buf/Z"
>',
        attachments: [
          'filename' => 'some_file.txt',
          'data' => 'dGVzdCAxMjM=',
          'mime-type' => 'text/plain',
        ],
      },
    }

    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #16', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])

    ticket = Ticket.find(result['id'])
    assert_equal(1, ticket.articles.count)
    assert_equal(2, ticket.articles.first.attachments.count)
    file = ticket.articles.first.attachments[0]
    assert_equal('006a2ca3793b550c8fe444acdeb39252', Digest::MD5.hexdigest(file.content))
    assert_match(/#{ticket.id}\..+?@zammad.example.com/, file.filename)
    assert_equal('image/jpeg', file.preferences['Mime-Type'])
    assert(file.preferences['Content-ID'])
    file = ticket.articles.first.attachments[1]
    assert_equal('39d0d586a701e199389d954f2d592720', Digest::MD5.hexdigest(file.content))
    assert_equal('some_file.txt', file.filename)
    assert_equal('text/plain', file.preferences['Mime-Type'])
    assert_not(file.preferences['Content-ID'])
  end

  test '02.02 ticket create with agent' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #1',
      state: 'new',
      priority: '2 normal',
      group: 'Users',
      customer: 'tickets-customer1@example.com',
      article: {
        content_type: 'text/plain', # or text/html
        body: 'some body',
      },
      links: {
        Ticket: {
          parent: [1],
        }
      }
    }
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #1', result['title'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
    links = Link.list(
      link_object: 'Ticket',
      link_object_value: result['id'],
    )
    assert_equal('child', links[0]['link_type'])
    assert_equal('Ticket', links[0]['link_object'])
    assert_equal(1, links[0]['link_object_value'])
  end

  test '02.03 ticket with wrong ticket id' do
    group = Group.create_or_update(
      name: "GroupWithoutPermission-#{rand(9_999_999_999)}",
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket = Ticket.create!(
      title: 'ticket with wrong ticket id',
      group_id: group.id,
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    get "/api/v1/tickets/#{ticket.id}", {}, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized', result['error'])

    params = {
      title: 'ticket with wrong ticket id - 2',
    }
    put "/api/v1/tickets/#{ticket.id}", params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized', result['error'])

    delete "/api/v1/tickets/#{ticket.id}", {}.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized', result['error'])
  end

  test '02.04 ticket with correct ticket id' do
    title = "ticket with corret ticket id testagent#{rand(999_999_999)}"
    ticket = Ticket.create!(
      title: title,
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    get "/api/v1/tickets/#{ticket.id}", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['id'])
    assert_equal(title, result['title'])
    assert_equal(ticket.customer_id, result['customer_id'])
    assert_equal(1, result['updated_by_id'])
    assert_equal(1, result['created_by_id'])

    params = {
      title: "#{title} - 2",
      customer_id: @agent.id,
    }
    put "/api/v1/tickets/#{ticket.id}", params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['id'])
    assert_equal("#{title} - 2", result['title'])
    assert_equal(@agent.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(1, result['created_by_id'])

    params = {
      ticket_id: ticket.id,
      subject: 'some subject',
      body: 'some body',
    }
    post '/api/v1/ticket_articles', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    article_result = JSON.parse(@response.body)
    assert_equal(Hash, article_result.class)
    assert_equal(ticket.id, article_result['ticket_id'])
    assert_equal('Tickets Agent', article_result['from'])
    assert_equal('some subject', article_result['subject'])
    assert_equal('some body', article_result['body'])
    assert_equal('text/plain', article_result['content_type'])
    assert_equal(false, article_result['internal'])
    assert_equal(@agent.id, article_result['created_by_id'])
    assert_equal(Ticket::Article::Sender.lookup(name: 'Agent').id, article_result['sender_id'])
    assert_equal(Ticket::Article::Type.lookup(name: 'note').id, article_result['type_id'])

    Scheduler.worker(true)
    get "/api/v1/tickets/search?query=#{CGI.escape(title)}", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['tickets'][0])
    assert_equal(1, result['tickets_count'])

    params = {
      condition: {
        'ticket.title' => {
          operator: 'contains',
          value: title,
        },
      },
    }
    post '/api/v1/tickets/search', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['tickets'][0])
    assert_equal(1, result['tickets_count'])

    delete "/api/v1/ticket_articles/#{article_result['id']}", {}.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)

    params = {
      from: 'something which should not be changed on server side',
      ticket_id: ticket.id,
      subject: 'some subject',
      body: 'some body',
      type: 'email',
      internal: true,
    }
    post '/api/v1/ticket_articles', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['ticket_id'])
    assert_equal('"Tickets Agent via Zammad" <zammad@localhost>', result['from'])
    assert_equal('some subject', result['subject'])
    assert_equal('some body', result['body'])
    assert_equal('text/plain', result['content_type'])
    assert_equal(true, result['internal'])
    assert_equal(@agent.id, result['created_by_id'])
    assert_equal(Ticket::Article::Sender.lookup(name: 'Agent').id, result['sender_id'])
    assert_equal(Ticket::Article::Type.lookup(name: 'email').id, result['type_id'])

    params = {
      subject: 'new subject',
    }
    put "/api/v1/ticket_articles/#{result['id']}", params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['ticket_id'])
    assert_equal('"Tickets Agent via Zammad" <zammad@localhost>', result['from'])
    assert_equal('new subject', result['subject'])
    assert_equal('some body', result['body'])
    assert_equal('text/plain', result['content_type'])
    assert_equal(true, result['internal'])
    assert_equal(@agent.id, result['created_by_id'])
    assert_equal(Ticket::Article::Sender.lookup(name: 'Agent').id, result['sender_id'])
    assert_equal(Ticket::Article::Type.lookup(name: 'email').id, result['type_id'])

    delete "/api/v1/ticket_articles/#{result['id']}", {}.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized (admin permission required)!', result['error'])

    delete "/api/v1/tickets/#{ticket.id}", {}.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized (admin permission required)!', result['error'])
  end

  test '02.05 ticket with correct ticket id' do
    ticket = Ticket.create!(
      title: 'ticket with corret ticket id',
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')
    get "/api/v1/tickets/#{ticket.id}", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['id'])
    assert_equal('ticket with corret ticket id', result['title'])
    assert_equal(ticket.customer_id, result['customer_id'])
    assert_equal(1, result['updated_by_id'])
    assert_equal(1, result['created_by_id'])

    params = {
      title: 'ticket with corret ticket id - 2',
      customer_id: @agent.id,
    }
    put "/api/v1/tickets/#{ticket.id}", params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['id'])
    assert_equal('ticket with corret ticket id - 2', result['title'])
    assert_equal(@agent.id, result['customer_id'])
    assert_equal(@admin.id, result['updated_by_id'])
    assert_equal(1, result['created_by_id'])

    params = {
      from: 'something which should not be changed on server side',
      ticket_id: ticket.id,
      subject: 'some subject',
      body: 'some body',
    }
    post '/api/v1/ticket_articles', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['ticket_id'])
    assert_equal('Tickets Admin', result['from'])
    assert_equal('some subject', result['subject'])
    assert_equal('some body', result['body'])
    assert_equal('text/plain', result['content_type'])
    assert_equal(false, result['internal'])
    assert_equal(@admin.id, result['created_by_id'])
    assert_equal(Ticket::Article::Sender.lookup(name: 'Agent').id, result['sender_id'])
    assert_equal(Ticket::Article::Type.lookup(name: 'note').id, result['type_id'])

    params = {
      subject: 'new subject',
      internal: true,
    }
    put "/api/v1/ticket_articles/#{result['id']}", params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['ticket_id'])
    assert_equal('Tickets Admin', result['from'])
    assert_equal('new subject', result['subject'])
    assert_equal('some body', result['body'])
    assert_equal('text/plain', result['content_type'])
    assert_equal(true, result['internal'])
    assert_equal(@admin.id, result['created_by_id'])
    assert_equal(Ticket::Article::Sender.lookup(name: 'Agent').id, result['sender_id'])
    assert_equal(Ticket::Article::Type.lookup(name: 'note').id, result['type_id'])

    delete "/api/v1/ticket_articles/#{result['id']}", {}.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)

    params = {
      ticket_id: ticket.id,
      subject: 'some subject',
      body: 'some body',
      type: 'email',
    }
    post '/api/v1/ticket_articles', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['ticket_id'])
    assert_equal('"Tickets Admin via Zammad" <zammad@localhost>', result['from'])
    assert_equal('some subject', result['subject'])
    assert_equal('some body', result['body'])
    assert_equal('text/plain', result['content_type'])
    assert_equal(false, result['internal'])
    assert_equal(@admin.id, result['created_by_id'])
    assert_equal(Ticket::Article::Sender.lookup(name: 'Agent').id, result['sender_id'])
    assert_equal(Ticket::Article::Type.lookup(name: 'email').id, result['type_id'])

    delete "/api/v1/ticket_articles/#{result['id']}", {}.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)

    delete "/api/v1/tickets/#{ticket.id}", {}.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
  end

  test '02.05 ticket pagination' do
    title = "ticket pagination #{rand(999_999_999)}"
    tickets = []
    (1..20).each { |count|
      ticket = Ticket.create!(
        title: "#{title} - #{count}",
        group: Group.lookup(name: 'Users'),
        customer_id: @customer_without_org.id,
        state: Ticket::State.lookup(name: 'new'),
        priority: Ticket::Priority.lookup(name: '2 normal'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        type: Ticket::Article::Type.lookup(name: 'note'),
        sender: Ticket::Article::Sender.lookup(name: 'Customer'),
        from: 'sender',
        subject: 'subject',
        body: 'some body',
        ticket_id: ticket.id,
        updated_by_id: 1,
        created_by_id: 1,
      )
      tickets.push ticket
      travel 2.seconds
    }

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')
    get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(tickets[19].id, result['tickets'][0])
    assert_equal(tickets[0].id, result['tickets'][19])
    assert_equal(20, result['tickets_count'])

    get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=10", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(tickets[19].id, result['tickets'][0])
    assert_equal(tickets[10].id, result['tickets'][9])
    assert_equal(10, result['tickets_count'])

    get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40&page=1&per_page=5", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(tickets[19].id, result['tickets'][0])
    assert_equal(tickets[15].id, result['tickets'][4])
    assert_equal(5, result['tickets_count'])

    get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40&page=2&per_page=5", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(tickets[14].id, result['tickets'][0])
    assert_equal(tickets[10].id, result['tickets'][4])
    assert_equal(5, result['tickets_count'])

    get '/api/v1/tickets?limit=40&page=1&per_page=5', {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    tickets = Ticket.order(:id).limit(5)
    assert_equal(tickets[0].id, result[0]['id'])
    assert_equal(tickets[4].id, result[4]['id'])
    assert_equal(5, result.count)

    get '/api/v1/tickets?limit=40&page=2&per_page=5', {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    tickets = Ticket.order(:id).limit(10)
    assert_equal(tickets[5].id, result[0]['id'])
    assert_equal(tickets[9].id, result[4]['id'])
    assert_equal(5, result.count)

  end

  test '03.01 ticket create with customer minimal' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-customer1@example.com', 'customer1pw')
    params = {
      title: 'a new ticket #c1',
      state: 'new',
      priority: '2 normal',
      group: 'Users',
      article: {
        body: 'some body',
      },
    }
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #c1', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@customer_without_org.id, result['updated_by_id'])
    assert_equal(@customer_without_org.id, result['created_by_id'])
  end

  test '03.02 ticket create with customer with wrong customer' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-customer1@example.com', 'customer1pw')
    params = {
      title: 'a new ticket #c2',
      state: 'new',
      priority: '2 normal',
      group: 'Users',
      customer_id: @agent.id,
      article: {
        content_type: 'text/plain', # or text/html
        body: 'some body',
        sender: 'System',
      },
    }
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #c2', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@customer_without_org.id, result['updated_by_id'])
    assert_equal(@customer_without_org.id, result['created_by_id'])
  end

  test '03.03 ticket with wrong ticket id' do
    ticket = Ticket.create!(
      title: 'ticket with wrong ticket id',
      group: Group.lookup(name: 'Users'),
      customer_id: @agent.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-customer1@example.com', 'customer1pw')
    get "/api/v1/tickets/#{ticket.id}", {}, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized', result['error'])

    params = {
      title: 'ticket with wrong ticket id - 2',
    }
    put "/api/v1/tickets/#{ticket.id}", params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized', result['error'])

    delete "/api/v1/tickets/#{ticket.id}", {}.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized', result['error'])
  end

  test '03.04 ticket with correct ticket id' do
    title = "ticket with corret ticket id testme#{rand(999_999_999)}"
    ticket = Ticket.create!(
      title: title,
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-customer1@example.com', 'customer1pw')
    get "/api/v1/tickets/#{ticket.id}", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['id'])
    assert_equal(title, result['title'])
    assert_equal(ticket.customer_id, result['customer_id'])
    assert_equal(1, result['updated_by_id'])
    assert_equal(1, result['created_by_id'])

    params = {
      title: "#{title} - 2",
      customer_id: @agent.id,
    }
    put "/api/v1/tickets/#{ticket.id}", params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['id'])
    assert_equal("#{title} - 2", result['title'])
    assert_equal(ticket.customer_id, result['customer_id'])
    assert_equal(@customer_without_org.id, result['updated_by_id'])
    assert_equal(1, result['created_by_id'])

    params = {
      ticket_id: ticket.id,
      subject: 'some subject',
      body: 'some body',
    }
    post '/api/v1/ticket_articles', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    article_result = JSON.parse(@response.body)
    assert_equal(Hash, article_result.class)
    assert_equal(ticket.id, article_result['ticket_id'])
    assert_equal('Tickets Customer1', article_result['from'])
    assert_equal('some subject', article_result['subject'])
    assert_equal('some body', article_result['body'])
    assert_equal('text/plain', article_result['content_type'])
    assert_equal(@customer_without_org.id, article_result['created_by_id'])
    assert_equal(Ticket::Article::Sender.lookup(name: 'Customer').id, article_result['sender_id'])
    assert_equal(Ticket::Article::Type.lookup(name: 'note').id, article_result['type_id'])

    Scheduler.worker(true)
    get "/api/v1/tickets/search?query=#{CGI.escape(title)}", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['tickets'][0])
    assert_equal(1, result['tickets_count'])

    params = {
      condition: {
        'ticket.title' => {
          operator: 'contains',
          value: title,
        },
      },
    }
    post '/api/v1/tickets/search', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['tickets'][0])
    assert_equal(1, result['tickets_count'])

    delete "/api/v1/ticket_articles/#{article_result['id']}", {}.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized (admin permission required)!', result['error'])

    params = {
      ticket_id: ticket.id,
      subject: 'some subject',
      body: 'some body',
      type: 'email',
      sender: 'Agent',
    }
    post '/api/v1/ticket_articles', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['ticket_id'])
    assert_equal('Tickets Customer1', result['from'])
    assert_equal('some subject', result['subject'])
    assert_equal('some body', result['body'])
    assert_equal('text/plain', result['content_type'])
    assert_equal(@customer_without_org.id, result['created_by_id'])
    assert_equal(Ticket::Article::Sender.lookup(name: 'Customer').id, result['sender_id'])
    assert_equal(Ticket::Article::Type.lookup(name: 'note').id, result['type_id'])

    delete "/api/v1/ticket_articles/#{result['id']}", {}.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized (admin permission required)!', result['error'])

    params = {
      from: 'something which should not be changed on server side',
      ticket_id: ticket.id,
      subject: 'some subject',
      body: 'some body',
      type: 'web',
      sender: 'Agent',
      internal: true,
    }

    post '/api/v1/ticket_articles', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['ticket_id'])
    assert_equal('Tickets Customer1 <tickets-customer1@example.com>', result['from'])
    assert_equal('some subject', result['subject'])
    assert_equal('some body', result['body'])
    assert_equal('text/plain', result['content_type'])
    assert_equal(false, result['internal'])
    assert_equal(@customer_without_org.id, result['created_by_id'])
    assert_equal(Ticket::Article::Sender.lookup(name: 'Customer').id, result['sender_id'])
    assert_equal(Ticket::Article::Type.lookup(name: 'web').id, result['type_id'])

    params = {
      subject: 'new subject',
    }
    put "/api/v1/ticket_articles/#{result['id']}", params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized (ticket.agent or admin permission required)!', result['error'])

    delete "/api/v1/tickets/#{ticket.id}", {}.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized (admin permission required)!', result['error'])
  end

end
