# encoding: utf-8
require 'test_helper'
require 'rake'

class FormControllerTest < ActionDispatch::IntegrationTest
  setup do
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json', 'REMOTE_ADDR' => '1.2.3.4' }

    if ENV['ES_URL'].present?

      #fail "ERROR: Need ES_URL - hint ES_URL='http://127.0.0.1:9200'"
      Setting.set('es_url', ENV['ES_URL'])

      # Setting.set('es_url', 'http://127.0.0.1:9200')
      # Setting.set('es_index', 'estest.local_zammad')
      # Setting.set('es_user', 'elasticsearch')
      # Setting.set('es_password', 'zammad')

      if ENV['ES_INDEX_RAND'].present?
        ENV['ES_INDEX'] = "es_index_#{rand(999_999_999)}"
      end
      if ENV['ES_INDEX'].blank?
        raise "ERROR: Need ES_INDEX - hint ES_INDEX='estest.local_zammad'"
      end
      Setting.set('es_index', ENV['ES_INDEX'])
    end

    Ticket.destroy_all

    # drop/create indexes
    Setting.reload
    Rake::Task.clear
    Zammad::Application.load_tasks
    Rake::Task['searchindex:rebuild'].execute
  end

  teardown do
    if ENV['ES_URL'].present?
      Rake::Task['searchindex:drop'].execute
    end
  end

  test '01 - get config call' do
    post '/api/v1/form_config', {}.to_json, @headers
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert_equal(result['error'], 'Not authorized')
  end

  test '02 - get config call' do
    Setting.set('form_ticket_create', true)
    post '/api/v1/form_config', {}.to_json, @headers
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert_equal(result['error'], 'Not authorized')

  end

  test '03 - get config call & do submit' do
    Setting.set('form_ticket_create', true)
    fingerprint = SecureRandom.hex(40)
    post '/api/v1/form_config', { fingerprint: fingerprint }.to_json, @headers

    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert_equal(result['enabled'], true)
    assert_equal(result['endpoint'], 'http://zammad.example.com/api/v1/form_submit')
    assert(result['token'])
    token = result['token']

    post '/api/v1/form_submit', { fingerprint: fingerprint, token: 'invalid' }.to_json, @headers
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert_equal(result['error'], 'Not authorized')

    post '/api/v1/form_submit', { fingerprint: fingerprint, token: token }.to_json, @headers
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)

    assert(result['errors'])
    assert_equal(result['errors']['name'], 'required')
    assert_equal(result['errors']['email'], 'required')
    assert_equal(result['errors']['title'], 'required')
    assert_equal(result['errors']['body'], 'required')

    post '/api/v1/form_submit', { fingerprint: fingerprint, token: token, email: 'some' }.to_json, @headers
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)

    assert(result['errors'])
    assert_equal(result['errors']['name'], 'required')
    assert_equal(result['errors']['email'], 'invalid')
    assert_equal(result['errors']['title'], 'required')
    assert_equal(result['errors']['body'], 'required')

    post '/api/v1/form_submit', { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@znuny.com', title: 'test', body: 'hello' }.to_json, @headers
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)

    assert_not(result['errors'])
    assert(result['ticket'])
    assert(result['ticket']['id'])
    assert(result['ticket']['number'])

    travel 5.hours

    post '/api/v1/form_submit', { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@znuny.com', title: 'test', body: 'hello' }.to_json, @headers

    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)

    assert_not(result['errors'])
    assert(result['ticket'])
    assert(result['ticket']['id'])
    assert(result['ticket']['number'])

    travel 20.hours

    post '/api/v1/form_submit', { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@znuny.com', title: 'test', body: 'hello' }.to_json, @headers
    assert_response(401)

  end

  test '04 - get config call & do submit' do
    Setting.set('form_ticket_create', true)
    fingerprint = SecureRandom.hex(40)
    post '/api/v1/form_config', { fingerprint: fingerprint }.to_json, @headers

    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert_equal(result['enabled'], true)
    assert_equal(result['endpoint'], 'http://zammad.example.com/api/v1/form_submit')
    assert(result['token'])
    token = result['token']

    post '/api/v1/form_submit', { fingerprint: fingerprint, token: 'invalid' }.to_json, @headers
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert_equal(result['error'], 'Not authorized')

    post '/api/v1/form_submit', { fingerprint: fingerprint, token: token }.to_json, @headers
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)

    assert(result['errors'])
    assert_equal(result['errors']['name'], 'required')
    assert_equal(result['errors']['email'], 'required')
    assert_equal(result['errors']['title'], 'required')
    assert_equal(result['errors']['body'], 'required')

    post '/api/v1/form_submit', { fingerprint: fingerprint, token: token, email: 'some' }.to_json, @headers
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)

    assert(result['errors'])
    assert_equal(result['errors']['name'], 'required')
    assert_equal(result['errors']['email'], 'invalid')
    assert_equal(result['errors']['title'], 'required')
    assert_equal(result['errors']['body'], 'required')

    post '/api/v1/form_submit', { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'somebody@example.com', title: 'test', body: 'hello' }.to_json, @headers
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)

    assert(result['errors'])
    assert_equal(result['errors']['email'], 'invalid')

  end

  test '05 - limits' do
    return if !SearchIndexBackend.enabled?

    Setting.set('form_ticket_create', true)
    fingerprint = SecureRandom.hex(40)
    post '/api/v1/form_config', { fingerprint: fingerprint }.to_json, @headers

    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert_equal(result['enabled'], true)
    assert_equal(result['endpoint'], 'http://zammad.example.com/api/v1/form_submit')
    assert(result['token'])
    token = result['token']

    (1..20).each { |count|
      travel 10.seconds
      post '/api/v1/form_submit', { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@znuny.com', title: "test#{count}", body: 'hello' }.to_json, @headers
      assert_response(200)
      result = JSON.parse(@response.body)
      assert_equal(result.class, Hash)

      assert_not(result['errors'])
      assert(result['ticket'])
      assert(result['ticket']['id'])
      assert(result['ticket']['number'])
      Scheduler.worker(true)
      sleep 1 # wait until elasticsearch is index
    }

    sleep 10 # wait until elasticsearch is index

    post '/api/v1/form_submit', { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@znuny.com', title: 'test-last', body: 'hello' }.to_json, @headers
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert(result['error'])

    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json', 'REMOTE_ADDR' => '1.2.3.5' }

    (1..20).each { |count|
      travel 10.seconds
      post '/api/v1/form_submit', { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@znuny.com', title: "test-2-#{count}", body: 'hello' }.to_json, @headers
      assert_response(200)
      result = JSON.parse(@response.body)
      assert_equal(result.class, Hash)

      assert_not(result['errors'])
      assert(result['ticket'])
      assert(result['ticket']['id'])
      assert(result['ticket']['number'])
      Scheduler.worker(true)
      sleep 1 # wait until elasticsearch is index
    }

    sleep 10 # wait until elasticsearch is index

    post '/api/v1/form_submit', { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@znuny.com', title: 'test-2-last', body: 'hello' }.to_json, @headers
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert(result['error'])
  end

end
