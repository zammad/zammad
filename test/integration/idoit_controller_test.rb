
require 'test_helper'
require 'webmock/minitest'

class IdoitControllerTest < ActionDispatch::IntegrationTest
  setup do

    stub_request(:any, 'https://images.zammad.com/api/v1/person/image')
      .to_return(status: 404, body: '', headers: {})

    @token = 'some_token'
    @endpoint = 'https://idoit.example.com/i-doit/'

    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    Setting.set('idoit_integration', true)
    Setting.set('idoit_config', {
                  api_token: @token,
                  endpoint: @endpoint,
                  client_id: '',
                })
    groups = Group.where(name: 'Users')
    roles  = Role.where(name: %w[Agent])
    agent  = User.create_or_update(
      login: 'idoit-agent@example.com',
      firstname: 'E',
      lastname: 'S',
      email: 'idoit-agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1,
    )
    roles  = Role.where(name: %w[Agent Admin])
    admin  = User.create_or_update(
      login: 'idoit-admin@example.com',
      firstname: 'E',
      lastname: 'S',
      email: 'idoit-admin@example.com',
      password: 'adminpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1,
    )

    customer1 = User.create_or_update(
      login: 'ticket-idoit-customer1@example.com',
      firstname: 'CallerId',
      lastname: 'Customer1',
      email: 'ticket-idoit-customer1@example.com',
      password: 'customerpw',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )

  end

  test 'unclear urls' do

    agent_credentials = ActionController::HttpAuthentication::Basic.encode_credentials('idoit-agent@example.com', 'agentpw')
    params = {
      api_token: @token,
      endpoint: @endpoint,
      client_id: '',
    }
    post '/api/v1/integration/idoit/verify', params: params.to_json, headers: @headers.merge('Authorization' => agent_credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result.blank?)
    assert_equal('Not authorized (user)!', result['error'])

    stub_request(:post, "#{@endpoint}src/jsonrpc.php")
      .with(body: "{\"method\":\"cmdb.object_types\",\"params\":{\"apikey\":\"#{@token}\"},\"version\":\"2.0\"}")
      .to_return(status: 200, body: read_messaage('object_types_response'), headers: {})

    admin_credentials = ActionController::HttpAuthentication::Basic.encode_credentials('idoit-admin@example.com', 'adminpw')
    params = {
      api_token: @token,
      endpoint: @endpoint,
      client_id: '',
    }
    post '/api/v1/integration/idoit/verify', params: params.to_json, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result.blank?)
    assert_equal('ok', result['result'])
    assert(result['response'])
    assert_equal('2.0', result['response']['jsonrpc'])
    assert(result['response']['result'])

    params = {
      api_token: @token,
      endpoint: " #{@endpoint}/",
      client_id: '',
    }
    post '/api/v1/integration/idoit/verify', params: params.to_json, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result.blank?)
    assert_equal('ok', result['result'])
    assert(result['response'])
    assert_equal('2.0', result['response']['jsonrpc'])
    assert(result['response']['result'])

  end

  test 'list all object types' do

    stub_request(:post, "#{@endpoint}src/jsonrpc.php")
      .with(body: "{\"method\":\"cmdb.object_types\",\"params\":{\"apikey\":\"#{@token}\"},\"version\":\"2.0\"}")
      .to_return(status: 200, body: read_messaage('object_types_response'), headers: {})

    agent_credentials = ActionController::HttpAuthentication::Basic.encode_credentials('idoit-agent@example.com', 'agentpw')
    params = {
      method: 'cmdb.object_types',
    }
    post '/api/v1/integration/idoit', params: params.to_json, headers: @headers.merge('Authorization' => agent_credentials)
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result.blank?)
    assert_equal('ok', result['result'])
    assert(result['response'])
    assert_equal('2.0', result['response']['jsonrpc'])
    assert(result['response']['result'])
    assert_equal('1', result['response']['result'][0]['id'])
    assert_equal('System service', result['response']['result'][0]['title'])

    admin_credentials = ActionController::HttpAuthentication::Basic.encode_credentials('idoit-admin@example.com', 'adminpw')
    params = {
      method: 'cmdb.object_types',
    }
    post '/api/v1/integration/idoit', params: params.to_json, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result.blank?)
    assert_equal('ok', result['result'])
    assert(result['response'])
    assert_equal('2.0', result['response']['jsonrpc'])
    assert(result['response']['result'])
    assert_equal('1', result['response']['result'][0]['id'])
    assert_equal('System service', result['response']['result'][0]['title'])

  end

  test 'query objects' do

    stub_request(:post, "#{@endpoint}src/jsonrpc.php")
      .with(body: "{\"method\":\"cmdb.objects\",\"params\":{\"apikey\":\"#{@token}\",\"filter\":{\"ids\":[\"33\"]}},\"version\":\"2.0\"}")
      .to_return(status: 200, body: read_messaage('object_types_filter_response'), headers: {})

    agent_credentials = ActionController::HttpAuthentication::Basic.encode_credentials('idoit-agent@example.com', 'agentpw')
    params = {
      method: 'cmdb.objects',
      filter: {
        ids: ['33']
      },
    }
    post '/api/v1/integration/idoit', params: params.to_json, headers: @headers.merge('Authorization' => agent_credentials)
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result.blank?)
    assert_equal('ok', result['result'])
    assert(result['response'])
    assert_equal('2.0', result['response']['jsonrpc'])
    assert(result['response']['result'])
    assert_equal('26', result['response']['result'][0]['id'])
    assert_equal('demo.example.com', result['response']['result'][0]['title'])
    assert_equal('Virtual server', result['response']['result'][0]['type_title'])
    assert_equal('in operation', result['response']['result'][0]['cmdb_status_title'])

  end

  def read_messaage(file)
    File.read(Rails.root.join('test', 'data', 'idoit', "#{file}.json"))
  end

end
