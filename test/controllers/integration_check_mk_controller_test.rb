# encoding: utf-8
require 'test_helper'

class IntegationCheckMkControllerTest < ActionDispatch::IntegrationTest
  setup do
    token = SecureRandom.urlsafe_base64(16)
    Setting.set('check_mk_token', token)
    Setting.set('check_mk_integration', true)
  end

  test '01 without token' do
    post '/api/v1/integration/check_mk/', {}
    assert_response(404)
  end

  test '01 invalid token & enabled feature' do
    post '/api/v1/integration/check_mk/invalid_token', {}
    assert_response(422)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Invalid token!', result['error'])
  end

  test '01 invalid token & disabled feature' do
    Setting.set('check_mk_integration', false)

    post '/api/v1/integration/check_mk/invalid_token', {}
    assert_response(422)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Feature is disable, please contact your admin to enable it!', result['error'])
  end

  test '02 ticket create & close' do
    params = {
      event_id: '123',
      state: 'down',
      host: 'some host',
      service: 'some service',
    }
    post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    assert(result['result'])
    assert(result['ticket_id'])
    assert(result['ticket_number'])

    ticket = Ticket.find(result['ticket_id'])
    assert_equal('new', ticket.state.name)
    assert_equal(1, ticket.articles.count)

    params = {
      event_id: '123',
      state: 'up',
      host: 'some host',
      service: 'some service',
    }
    post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    assert(result['result'])
    assert(result['ticket_ids'].include?(ticket.id))

    ticket.reload
    assert_equal('closed', ticket.state.name)
    assert_equal(2, ticket.articles.count)
  end

  test '02 ticket create & create & auto close' do
    params = {
      event_id: '123',
      state: 'down',
      host: 'some host',
      service: 'some service',
    }
    post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    assert(result['result'])
    assert(result['ticket_id'])
    assert(result['ticket_number'])

    ticket = Ticket.find(result['ticket_id'])
    assert_equal('new', ticket.state.name)
    assert_equal(1, ticket.articles.count)

    params = {
      event_id: '123',
      state: 'down',
      host: 'some host',
      service: 'some service',
    }
    post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    assert_equal('ticket already open, added note', result['result'])
    assert(result['ticket_ids'].include?(ticket.id))

    ticket.reload
    assert_equal('new', ticket.state.name)
    assert_equal(2, ticket.articles.count)

    params = {
      event_id: '123',
      state: 'up',
      host: 'some host',
      service: 'some service',
    }
    post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    assert(result['result'])
    assert(result['ticket_ids'].include?(ticket.id))

    ticket.reload
    assert_equal('closed', ticket.state.name)
    assert_equal(3, ticket.articles.count)
  end

  test '02 ticket close' do
    params = {
      event_id: '123',
      state: 'up',
      host: 'some host',
      service: 'some service',
    }
    post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    assert_equal('no open tickets found, ignore action', result['result'])
  end

  test '02 ticket create & create & no auto close' do
    Setting.set('check_mk_auto_close', false)
    params = {
      event_id: '123',
      state: 'down',
      host: 'some host',
      service: 'some service',
    }
    post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    assert(result['result'])
    assert(result['ticket_id'])
    assert(result['ticket_number'])

    ticket = Ticket.find(result['ticket_id'])
    assert_equal('new', ticket.state.name)
    assert_equal(1, ticket.articles.count)

    params = {
      event_id: '123',
      state: 'down',
      host: 'some host',
      service: 'some service',
    }
    post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    assert_equal('ticket already open, added note', result['result'])
    assert(result['ticket_ids'].include?(ticket.id))

    ticket.reload
    assert_equal('new', ticket.state.name)
    assert_equal(2, ticket.articles.count)

    params = {
      event_id: '123',
      state: 'up',
      host: 'some host',
      service: 'some service',
    }
    post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    assert_equal('ticket already open, added note', result['result'])
    assert(result['ticket_ids'].include?(ticket.id))

    ticket.reload
    assert_equal('new', ticket.state.name)
    assert_equal(3, ticket.articles.count)
  end

  test '02 ticket create & create & auto close - host only' do
    params = {
      event_id: '123',
      state: 'down',
      host: 'some host',
    }
    post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    assert(result['result'])
    assert(result['ticket_id'])
    assert(result['ticket_number'])

    ticket = Ticket.find(result['ticket_id'])
    assert_equal('new', ticket.state.name)
    assert_equal(1, ticket.articles.count)

    params = {
      event_id: '123',
      state: 'down',
      host: 'some host',
    }
    post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    assert_equal('ticket already open, added note', result['result'])
    assert(result['ticket_ids'].include?(ticket.id))

    ticket.reload
    assert_equal('new', ticket.state.name)
    assert_equal(2, ticket.articles.count)

    params = {
      event_id: '123',
      state: 'up',
      host: 'some host',
    }
    post "/api/v1/integration/check_mk/#{Setting.get('check_mk_token')}", params
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    assert(result['result'])
    assert(result['ticket_ids'].include?(ticket.id))

    ticket.reload
    assert_equal('closed', ticket.state.name)
    assert_equal(3, ticket.articles.count)
  end
end
