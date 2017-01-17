# encoding: utf-8
require 'test_helper'

class MonitoringControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # set token
    @token = SecureRandom.urlsafe_base64(64)
    Setting.set('monitoring_token', @token)

    # create agent
    roles  = Role.where(name: %w(Admin Agent))
    groups = Group.all

    # channel cleanup
    Channel.where.not(area: 'Email::Notification').destroy_all
    Channel.all.each { |channel|
      channel.status_in  = 'ok'
      channel.status_out = 'ok'
      channel.last_log_in = nil
      channel.last_log_out = nil
      channel.save!
    }
    dir = "#{Rails.root}/tmp/unprocessable_mail"
    Dir.glob("#{dir}/*.eml") do |entry|
      File.delete(entry)
    end

    Scheduler.where(active: true).each { |scheduler|
      scheduler.last_run = Time.zone.now
      scheduler.save!
    }

    permission = Permission.find_by(name: 'admin.monitoring')
    permission.active = true
    permission.save!

    UserInfo.current_user_id = 1
    @admin = User.create_or_update(
      login: 'monitoring-admin',
      firstname: 'Monitoring',
      lastname: 'Admin',
      email: 'monitoring-admin@example.com',
      password: 'adminpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create agent
    roles = Role.where(name: 'Agent')
    @agent = User.create_or_update(
      login: 'monitoring-agent@example.com',
      firstname: 'Monitoring',
      lastname: 'Agent',
      email: 'monitoring-agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create customer without org
    roles = Role.where(name: 'Customer')
    @customer_without_org = User.create_or_update(
      login: 'monitoring-customer1@example.com',
      firstname: 'Monitoring',
      lastname: 'Customer1',
      email: 'monitoring-customer1@example.com',
      password: 'customer1pw',
      active: true,
      roles: roles,
    )

  end

  test '01 monitoring without token' do

    # health_check
    get '/api/v1/monitoring/health_check', {}, @headers
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['healthy'])
    assert_equal('Not authorized', result['error'])

    # status
    get '/api/v1/monitoring/status', {}, @headers
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['agents'])
    assert_not(result['last_login'])
    assert_not(result['counts'])
    assert_not(result['last_created_at'])
    assert_equal('Not authorized', result['error'])

    # token
    post '/api/v1/monitoring/token', {}, @headers
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['token'])
    assert_equal('authentication failed', result['error'])

  end

  test '02 monitoring with wrong token' do

    # health_check
    get '/api/v1/monitoring/health_check?token=abc', {}, @headers
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['healthy'])
    assert_equal('Not authorized', result['error'])

    # status
    get '/api/v1/monitoring/status?token=abc', {}, @headers
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['agents'])
    assert_not(result['last_login'])
    assert_not(result['counts'])
    assert_not(result['last_created_at'])
    assert_equal('Not authorized', result['error'])

    # token
    post '/api/v1/monitoring/token', { token: 'abc' }.to_json, @headers
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['token'])
    assert_equal('authentication failed', result['error'])

  end

  test '03 monitoring with correct token' do

    # health_check
    get "/api/v1/monitoring/health_check?token=#{@token}", {}, @headers
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['error'])
    assert_equal(true, result['healthy'])
    assert_equal('success', result['message'])

    # status
    get "/api/v1/monitoring/status?token=#{@token}", {}, @headers
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['error'])
    assert(result.key?('agents'))
    assert(result.key?('last_login'))
    assert(result.key?('counts'))
    assert(result.key?('last_created_at'))

    # token
    post '/api/v1/monitoring/token', { token: @token }.to_json, @headers
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['token'])
    assert_equal('authentication failed', result['error'])

  end

  test '04 monitoring with admin user' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('monitoring-admin@example.com', 'adminpw')

    # health_check
    get '/api/v1/monitoring/health_check', {}, @headers.merge('Authorization' => credentials)
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['error'])
    assert_equal(true, result['healthy'])
    assert_equal('success', result['message'])

    # status
    get '/api/v1/monitoring/status', {}, @headers.merge('Authorization' => credentials)
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['error'])
    assert(result.key?('agents'))
    assert(result.key?('last_login'))
    assert(result.key?('counts'))
    assert(result.key?('last_created_at'))

    # token
    post '/api/v1/monitoring/token', { token: @token }.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['token'])
    @token = result['token']
    assert_not(result['error'])

  end

  test '05 monitoring with agent user' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('monitoring-agent@example.com', 'agentpw')

    # health_check
    get '/api/v1/monitoring/health_check', {}, @headers.merge('Authorization' => credentials)
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['healthy'])
    assert_equal('Not authorized (user)!', result['error'])

    # status
    get '/api/v1/monitoring/status', {}, @headers.merge('Authorization' => credentials)
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['agents'])
    assert_not(result['last_login'])
    assert_not(result['counts'])
    assert_not(result['last_created_at'])
    assert_equal('Not authorized (user)!', result['error'])

    # token
    post '/api/v1/monitoring/token', { token: @token }.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['token'])
    assert_equal('Not authorized (user)!', result['error'])

  end

  test '06 monitoring with admin user and invalid permission' do

    permission = Permission.find_by(name: 'admin.monitoring')
    permission.active = false
    permission.save!

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('monitoring-admin@example.com', 'adminpw')

    # health_check
    get '/api/v1/monitoring/health_check', {}, @headers.merge('Authorization' => credentials)
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['healthy'])
    assert_equal('Not authorized (user)!', result['error'])

    # status
    get '/api/v1/monitoring/status', {}, @headers.merge('Authorization' => credentials)
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['agents'])
    assert_not(result['last_login'])
    assert_not(result['counts'])
    assert_not(result['last_created_at'])
    assert_equal('Not authorized (user)!', result['error'])

    # token
    post '/api/v1/monitoring/token', { token: @token }.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['token'])
    assert_equal('Not authorized (user)!', result['error'])

    permission.active = true
    permission.save!
  end

  test '07 monitoring with correct token and invalid permission' do

    permission = Permission.find_by(name: 'admin.monitoring')
    permission.active = false
    permission.save!

    # health_check
    get "/api/v1/monitoring/health_check?token=#{@token}", {}, @headers
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['error'])
    assert_equal(true, result['healthy'])
    assert_equal('success', result['message'])

    # status
    get "/api/v1/monitoring/status?token=#{@token}", {}, @headers
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['error'])
    assert(result.key?('agents'))
    assert(result.key?('last_login'))
    assert(result.key?('counts'))
    assert(result.key?('last_created_at'))

    # token
    post '/api/v1/monitoring/token', { token: @token }.to_json, @headers
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['token'])
    assert_equal('authentication failed', result['error'])

    permission.active = true
    permission.save!

  end

  test '08 check health false' do

    channel = Channel.find_by(active: true)
    channel.status_in  = 'ok'
    channel.status_out = 'error'
    channel.last_log_in = nil
    channel.last_log_out = nil
    channel.save!

    # health_check
    get "/api/v1/monitoring/health_check?token=#{@token}", {}, @headers
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['message'])
    assert(result['issues'])
    assert_equal(false, result['healthy'])
    assert_equal('Channel: Email::Notification out  ', result['message'])

    scheduler = Scheduler.where(active: true).last
    scheduler.last_run = Time.zone.now - 1.day
    scheduler.period = 600
    scheduler.save!

    # health_check
    get "/api/v1/monitoring/health_check?token=#{@token}", {}, @headers
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['message'])
    assert(result['issues'])
    assert_equal(false, result['healthy'])
    assert_equal('Channel: Email::Notification out  ;scheduler not running', result['message'])

    dir = "#{Rails.root}/tmp/unprocessable_mail"
    FileUtils.mkdir_p(dir)
    FileUtils.touch("#{dir}/test.eml")

    # health_check
    get "/api/v1/monitoring/health_check?token=#{@token}", {}, @headers
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['message'])
    assert(result['issues'])
    assert_equal(false, result['healthy'])
    assert_equal('Channel: Email::Notification out  ;unprocessable mails: 1;scheduler not running', result['message'])

  end

end
