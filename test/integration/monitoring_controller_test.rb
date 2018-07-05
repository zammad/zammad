require 'integration_test_helper'

class MonitoringControllerTest < ActionDispatch::IntegrationTest

  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # set token
    @token = SecureRandom.urlsafe_base64(64)
    Setting.set('monitoring_token', @token)

    # create agent
    roles  = Role.where(name: %w[Admin Agent])
    groups = Group.all

    # channel cleanup
    Channel.where.not(area: 'Email::Notification').destroy_all
    Channel.all.each do |channel|
      channel.status_in  = 'ok'
      channel.status_out = 'ok'
      channel.last_log_in = nil
      channel.last_log_out = nil
      channel.save!
    end
    dir = Rails.root.join('tmp', 'unprocessable_mail')
    Dir.glob("#{dir}/*.eml") do |entry|
      File.delete(entry)
    end

    Scheduler.where(active: true).each do |scheduler|
      scheduler.last_run = Time.zone.now
      scheduler.save!
    end

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
    get '/api/v1/monitoring/health_check', params: {}, headers: @headers
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['healthy'])
    assert_equal('Not authorized', result['error'])

    # status
    get '/api/v1/monitoring/status', params: {}, headers: @headers
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['agents'])
    assert_not(result['last_login'])
    assert_not(result['counts'])
    assert_not(result['last_created_at'])
    assert_equal('Not authorized', result['error'])

    # token
    post '/api/v1/monitoring/token', params: {}, headers: @headers
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['token'])
    assert_equal('authentication failed', result['error'])

  end

  test '02 monitoring with wrong token' do

    # health_check
    get '/api/v1/monitoring/health_check?token=abc', params: {}, headers: @headers
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['healthy'])
    assert_equal('Not authorized', result['error'])

    # status
    get '/api/v1/monitoring/status?token=abc', params: {}, headers: @headers
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['agents'])
    assert_not(result['last_login'])
    assert_not(result['counts'])
    assert_not(result['last_created_at'])
    assert_equal('Not authorized', result['error'])

    # token
    post '/api/v1/monitoring/token', params: { token: 'abc' }.to_json, headers: @headers
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['token'])
    assert_equal('authentication failed', result['error'])

  end

  test '03 monitoring with correct token' do

    # test storage usage
    string = ''
    10.times do
      string += 'Some Text Some Text Some Text Some Text Some Text Some Text Some Text Some Text'
    end
    Store.add(
      object: 'User',
      o_id: 1,
      data: string,
      filename: 'filename.txt',
    )

    # health_check
    get "/api/v1/monitoring/health_check?token=#{@token}", params: {}, headers: @headers
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['error'])
    assert_equal(true, result['healthy'])
    assert_equal('success', result['message'])

    # status
    get "/api/v1/monitoring/status?token=#{@token}", params: {}, headers: @headers
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['error'])
    assert(result.key?('agents'))
    assert(result.key?('last_login'))
    assert(result.key?('counts'))
    assert(result.key?('last_created_at'))

    if ActiveRecord::Base.connection_config[:adapter] == 'postgresql'
      assert(result['storage'])
      assert(result['storage'].key?('kB'))
      assert(result['storage'].key?('MB'))
      assert(result['storage'].key?('GB'))
    else
      assert_not(result['storage'])
    end

    # token
    post '/api/v1/monitoring/token', params: { token: @token }.to_json, headers: @headers
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['token'])
    assert_equal('authentication failed', result['error'])

  end

  test '04 monitoring with admin user' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('monitoring-admin@example.com', 'adminpw')

    # health_check
    get '/api/v1/monitoring/health_check', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['error'])
    assert_equal(true, result['healthy'])
    assert_equal('success', result['message'])

    # status
    get '/api/v1/monitoring/status', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['error'])
    assert(result.key?('agents'))
    assert(result.key?('last_login'))
    assert(result.key?('counts'))
    assert(result.key?('last_created_at'))

    # token
    post '/api/v1/monitoring/token', params: { token: @token }.to_json, headers: @headers.merge('Authorization' => credentials)
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
    get '/api/v1/monitoring/health_check', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['healthy'])
    assert_equal('Not authorized (user)!', result['error'])

    # status
    get '/api/v1/monitoring/status', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['agents'])
    assert_not(result['last_login'])
    assert_not(result['counts'])
    assert_not(result['last_created_at'])
    assert_equal('Not authorized (user)!', result['error'])

    # token
    post '/api/v1/monitoring/token', params: { token: @token }.to_json, headers: @headers.merge('Authorization' => credentials)
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
    get '/api/v1/monitoring/health_check', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['healthy'])
    assert_equal('Not authorized (user)!', result['error'])

    # status
    get '/api/v1/monitoring/status', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['agents'])
    assert_not(result['last_login'])
    assert_not(result['counts'])
    assert_not(result['last_created_at'])
    assert_equal('Not authorized (user)!', result['error'])

    # token
    post '/api/v1/monitoring/token', params: { token: @token }.to_json, headers: @headers.merge('Authorization' => credentials)
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
    get "/api/v1/monitoring/health_check?token=#{@token}", params: {}, headers: @headers
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['error'])
    assert_equal(true, result['healthy'])
    assert_equal('success', result['message'])

    # status
    get "/api/v1/monitoring/status?token=#{@token}", params: {}, headers: @headers
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['error'])
    assert(result.key?('agents'))
    assert(result.key?('last_login'))
    assert(result.key?('counts'))
    assert(result.key?('last_created_at'))

    # token
    post '/api/v1/monitoring/token', params: { token: @token }.to_json, headers: @headers
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
    get "/api/v1/monitoring/health_check?token=#{@token}", params: {}, headers: @headers
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
    get "/api/v1/monitoring/health_check?token=#{@token}", params: {}, headers: @headers
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['message'])
    assert(result['issues'])
    assert_equal(false, result['healthy'])
    assert_equal('Channel: Email::Notification out  ;scheduler not running', result['message'])

    dir = Rails.root.join('tmp', 'unprocessable_mail')
    FileUtils.mkdir_p(dir)
    FileUtils.touch("#{dir}/test.eml")

    # health_check
    get "/api/v1/monitoring/health_check?token=#{@token}", params: {}, headers: @headers
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['message'])
    assert(result['issues'])
    assert_equal(false, result['healthy'])
    assert_equal('Channel: Email::Notification out  ;unprocessable mails: 1;scheduler not running', result['message'])

    Setting.set('ldap_integration', true)

    ImportJob.create(
      name:        'Import::Ldap',
      started_at:  Time.zone.now,
      finished_at: Time.zone.now,
      result:      {
        error: 'Some bad error'
      }
    )

    # health_check
    get "/api/v1/monitoring/health_check?token=#{@token}", params: {}, headers: @headers
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['message'])
    assert(result['issues'])
    assert_equal(false, result['healthy'])
    assert_equal("Channel: Email::Notification out  ;unprocessable mails: 1;scheduler not running;Failed to run import backend 'Import::Ldap'. Cause: Some bad error", result['message'])

    stuck_updated_at_timestamp = 15.minutes.ago
    ImportJob.create(
      name:        'Import::Ldap',
      started_at:  Time.zone.now,
      finished_at: nil,
      updated_at:  stuck_updated_at_timestamp,
    )

    # health_check
    get "/api/v1/monitoring/health_check?token=#{@token}", params: {}, headers: @headers
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['message'])
    assert(result['issues'])
    assert_equal(false, result['healthy'])
    assert_equal("Channel: Email::Notification out  ;unprocessable mails: 1;scheduler not running;Failed to run import backend 'Import::Ldap'. Cause: Some bad error;Stuck import backend 'Import::Ldap' detected. Last update: #{stuck_updated_at_timestamp}", result['message'])

    Setting.set('ldap_integration', false)
  end

  test '09 check restart_failed_jobs' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('monitoring-admin@example.com', 'adminpw')
    post '/api/v1/monitoring/restart_failed_jobs', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
  end

  test '10 check failed delayed job' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('monitoring-admin@example.com', 'adminpw')

    # disable elasticsearch
    prev_es_config = Setting.get('es_url')
    Setting.set('es_url', 'http://127.0.0.1:92001')

    # add a new object
    object = ObjectManager::Attribute.add(
      name: 'test3',
      object: 'Ticket',
      display: 'Test 3',
      active: true,
      data_type: 'input',
      data_option: {
        default: 'test',
        type: 'text',
        maxlength: 120,
        null: true
      },
      screens: {
        create_middle: {
          'ticket.customer' => {
            shown: true,
            item_class: 'column'
          },
          'ticket.agent' => {
            shown: true,
            item_class: 'column'
          }
        },
        edit: {
          'ticket.customer' => {
            shown: true
          },
          'ticket.agent' => {
            shown: true
          }
        }
      },
      position: 1550,
      editable: true
    )

    migration = ObjectManager::Attribute.migration_execute
    assert_equal(migration, true)

    post "/api/v1/object_manager_attributes/#{object.id}", params: {}, headers: @headers
    token = @response.headers['CSRF-TOKEN']

    # parameters for updating
    params = {
      'name': 'test4',
      'object': 'Ticket',
      'display': 'Test 4',
      'active': true,
      'data_type': 'input',
      'data_option': {
        'default': 'test',
        'type': 'text',
        'maxlength': 120
      },
      'screens': {
        'create_middle': {
          'ticket.customer': {
            'shown': true,
            'item_class': 'column'
          },
          'ticket.agent': {
            'shown': true,
            'item_class': 'column'
          }
        },
        'edit': {
          'ticket.customer': {
            'shown': true
          },
          'ticket.agent': {
            'shown': true
          }
        }
      },
      'id': 'c-196'
    }

    # update the object
    put "/api/v1/object_manager_attributes/#{object.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)

    migration = ObjectManager::Attribute.migration_execute
    assert_equal(migration, true)

    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)
    assert(result['data_option']['null'])
    assert_equal(result['name'], 'test4')
    assert_equal(result['display'], 'Test 4')

    jobs = Delayed::Job.all

    4.times do
      jobs.each do |job|
        Delayed::Worker.new.run(job)
      end
    end

    # health_check
    get "/api/v1/monitoring/health_check?token=#{@token}", params: {}, headers: @headers
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['message'])
    assert(result['issues'])
    assert_equal(false, result['healthy'])
    assert_equal("Failed to run background job #1 'BackgroundJobSearchIndex' 1 time(s) with 4 attempt(s).",  result['message'])

    # add another job
    manual_added = Delayed::Job.enqueue( BackgroundJobSearchIndex.new('Ticket', 1))
    manual_added.update!(attempts: 10)

    # health_check
    get "/api/v1/monitoring/health_check?token=#{@token}", params: {}, headers: @headers
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['message'])
    assert(result['issues'])
    assert_equal(false, result['healthy'])
    assert_equal("Failed to run background job #1 'BackgroundJobSearchIndex' 2 time(s) with 14 attempt(s).",  result['message'])

    # add another job
    dummy_class = Class.new do

      def perform
        puts 'work work'
      end
    end

    manual_added = Delayed::Job.enqueue( dummy_class.new )
    manual_added.update!(attempts: 5)

    # health_check
    get "/api/v1/monitoring/health_check?token=#{@token}", params: {}, headers: @headers
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['message'])
    assert(result['issues'])
    assert_equal(false, result['healthy'])
    assert_equal("Failed to run background job #1 'BackgroundJobSearchIndex' 2 time(s) with 14 attempt(s).;Failed to run background job #2 'Object' 1 time(s) with 5 attempt(s).",  result['message'])

    # reset settings
    Setting.set('es_url', prev_es_config)

    # add some more failing job
    10.times do
      manual_added = Delayed::Job.enqueue( dummy_class.new )
      manual_added.update!(attempts: 5)
    end

    # health_check
    get "/api/v1/monitoring/health_check?token=#{@token}", params: {}, headers: @headers
    assert_response(200)

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['message'])
    assert(result['issues'])
    assert_equal(false, result['healthy'])
    assert_equal("13 failing background jobs.;Failed to run background job #1 'Object' 8 time(s) with 40 attempt(s).;Failed to run background job #2 'BackgroundJobSearchIndex' 2 time(s) with 14 attempt(s).",  result['message'])

    # cleanup
    Delayed::Job.delete_all
  end
end
