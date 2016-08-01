# encoding: utf-8
require 'test_helper'

class UserDeviceControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # create agent
    roles  = Role.where( name: %w(Admin Agent) )
    groups = Group.all

    UserInfo.current_user_id = 1
    @admin = User.create_or_update(
      login: 'user-device-admin',
      firstname: 'UserDevice',
      lastname: 'Admin',
      email: 'user-device-admin@example.com',
      password: 'adminpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create agent
    roles = Role.where( name: 'Agent' )
    @agent = User.create_or_update(
      login: 'user-device-agent',
      firstname: 'UserDevice',
      lastname: 'Agent',
      email: 'user-device-agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    ENV['TEST_REMOTE_IP'] = '5.9.62.170' # de
    ENV['HTTP_USER_AGENT'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11; rv:46.0) Gecko/20100101 Firefox/46.0'
  end

  test '01 - index with nobody' do

    get '/api/v1/signshow'
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert_equal(result['error'], 'no valid session')
    assert(result['config'])
    assert_not(controller.session[:user_device_fingerprint])

    Scheduler.worker(true)

  end

  test '02 - login index with admin without fingerprint' do

    assert_equal(0, UserDevice.where(user_id: @admin.id).count)
    assert_equal(0, email_notification_count('user_device_new', @admin.email))
    assert_equal(0, email_notification_count('user_device_new_location', @admin.email))

    params = { without_fingerprint: 'none', username: 'user-device-admin', password: 'adminpw' }
    post '/api/v1/signin', params.to_json, @headers
    assert_response(422)
    result = JSON.parse(@response.body)

    assert_equal(result.class, Hash)
    assert_equal('Need fingerprint param!', result['error'])
    assert_not(result['config'])
    assert_not(controller.session[:user_device_fingerprint])

    Scheduler.worker(true)

    assert_equal(0, UserDevice.where(user_id: @admin.id).count)
    assert_equal(0, email_notification_count('user_device_new', @admin.email))
    assert_equal(0, email_notification_count('user_device_new_location', @admin.email))

  end

  test '03 - login index with admin with fingerprint - I' do

    assert_equal(0, UserDevice.where(user_id: @admin.id).count)
    assert_equal(0, email_notification_count('user_device_new', @admin.email))
    assert_equal(0, email_notification_count('user_device_new_location', @admin.email))

    params = { fingerprint: 'my_finger_print', username: 'user-device-admin', password: 'adminpw' }
    post '/api/v1/signin', params.to_json, @headers
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert_not(result['error'])
    assert(result['config'])
    assert('my_finger_print', controller.session[:user_device_fingerprint])

    Scheduler.worker(true)

    assert_equal(1, UserDevice.where(user_id: @admin.id).count)
    assert_equal(0, email_notification_count('user_device_new', @admin.email))
    assert_equal(0, email_notification_count('user_device_new_location', @admin.email))
    user_device_first = UserDevice.last
    sleep 2

    params = {}
    get '/api/v1/users', params.to_json, @headers
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Array)
    assert('my_finger_print', controller.session[:user_device_fingerprint])

    Scheduler.worker(true)

    assert_equal(1, UserDevice.where(user_id: @admin.id).count)
    assert_equal(0, email_notification_count('user_device_new', @admin.email))
    assert_equal(0, email_notification_count('user_device_new_location', @admin.email))
    user_device_last = UserDevice.last
    assert_equal(user_device_last.updated_at.to_s, user_device_first.updated_at.to_s)

    params = { fingerprint: 'my_finger_print' }
    get '/api/v1/signshow', params, @headers
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert(result['session'])
    assert_equal(result['session']['login'], 'user-device-admin')
    assert(result['config'])

    Scheduler.worker(true)

    assert_equal(1, UserDevice.where(user_id: @admin.id).count)
    assert_equal(0, email_notification_count('user_device_new', @admin.email))
    assert_equal(0, email_notification_count('user_device_new_location', @admin.email))
    user_device_last = UserDevice.last
    assert_equal(user_device_last.updated_at.to_s, user_device_first.updated_at.to_s)

    ENV['USER_DEVICE_UPDATED_AT'] = (Time.zone.now - 4.hours).to_s
    params = {}
    get '/api/v1/users', params.to_json, @headers
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Array)
    assert('my_finger_print', controller.session[:user_device_fingerprint])

    Scheduler.worker(true)

    assert_equal(1, UserDevice.where(user_id: @admin.id).count)
    assert_equal(0, email_notification_count('user_device_new', @admin.email))
    assert_equal(0, email_notification_count('user_device_new_location', @admin.email))
    user_device_last = UserDevice.last
    assert_not_equal(user_device_last.updated_at.to_s, user_device_first.updated_at.to_s)
    ENV['USER_DEVICE_UPDATED_AT'] = nil

    ENV['TEST_REMOTE_IP'] = '195.65.29.254' # ch

    params = {}
    get '/api/v1/users', params.to_json, @headers
    assert_response(200)
    result = JSON.parse(@response.body)

    Scheduler.worker(true)

    assert_equal(2, UserDevice.where(user_id: @admin.id).count)
    assert_equal(0, email_notification_count('user_device_new', @admin.email))
    assert_equal(1, email_notification_count('user_device_new_location', @admin.email))

    # ip reset
    ENV['TEST_REMOTE_IP'] = '5.9.62.170' # de

  end

  test '04 - login index with admin with fingerprint - II' do

    params = { fingerprint: 'my_finger_print_II', username: 'user-device-admin', password: 'adminpw' }
    post '/api/v1/signin', params.to_json, @headers
    assert_response(201)
    result = JSON.parse(@response.body)

    Scheduler.worker(true)

    assert_equal(3, UserDevice.where(user_id: @admin.id).count)
    assert_equal(1, email_notification_count('user_device_new', @admin.email))
    assert_equal(0, email_notification_count('user_device_new_location', @admin.email))
    assert_equal(result.class, Hash)
    assert_not(result['error'])
    assert(result['config'])
    assert('my_finger_print_II', controller.session[:user_device_fingerprint])

    get '/api/v1/users', params.to_json, @headers
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Array)

    Scheduler.worker(true)

    assert_equal(3, UserDevice.where(user_id: @admin.id).count)
    assert_equal(1, email_notification_count('user_device_new', @admin.email))
    assert_equal(0, email_notification_count('user_device_new_location', @admin.email))

    params = { fingerprint: 'my_finger_print_II' }
    get '/api/v1/signshow', params, @headers
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert(result['session'])
    assert_equal(result['session']['login'], 'user-device-admin')
    assert(result['config'])

    Scheduler.worker(true)

    assert_equal(3, UserDevice.where(user_id: @admin.id).count)
    assert_equal(1, email_notification_count('user_device_new', @admin.email))
    assert_equal(0, email_notification_count('user_device_new_location', @admin.email))

    ENV['TEST_REMOTE_IP'] = '195.65.29.254' # ch

    params = {}
    get '/api/v1/users', params.to_json, @headers
    assert_response(200)
    result = JSON.parse(@response.body)

    Scheduler.worker(true)

    assert_equal(4, UserDevice.where(user_id: @admin.id).count)
    assert_equal(1, email_notification_count('user_device_new', @admin.email))
    assert_equal(1, email_notification_count('user_device_new_location', @admin.email))

    # ip reset
    ENV['TEST_REMOTE_IP'] = '5.9.62.170' # de

  end

  test '05 - login index with admin with fingerprint - II' do

    params = { fingerprint: 'my_finger_print_II', username: 'user-device-admin', password: 'adminpw' }
    post '/api/v1/signin', params.to_json, @headers
    assert_response(201)
    result = JSON.parse(@response.body)

    Scheduler.worker(true)

    assert_equal(4, UserDevice.where(user_id: @admin.id).count)
    assert_equal(0, email_notification_count('user_device_new', @admin.email))
    assert_equal(0, email_notification_count('user_device_new_location', @admin.email))
    assert_equal(result.class, Hash)
    assert_not(result['error'])
    assert(result['config'])
    assert('my_finger_print_II', controller.session[:user_device_fingerprint])
  end

  test '06 - login index with admin with basic auth' do

    ENV['HTTP_USER_AGENT'] = 'curl 1.2.3'
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('user-device-admin', 'adminpw')

    params = {}
    get '/api/v1/users', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)

    Scheduler.worker(true)

    assert_equal(5, UserDevice.where(user_id: @admin.id).count)
    assert_equal(1, email_notification_count('user_device_new', @admin.email))
    assert_equal(0, email_notification_count('user_device_new_location', @admin.email))
    assert_equal(result.class, Array)
    user_device_first = UserDevice.last
    sleep 2

    params = {}
    get '/api/v1/users', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)

    Scheduler.worker(true)

    assert_equal(5, UserDevice.where(user_id: @admin.id).count)
    assert_equal(1, email_notification_count('user_device_new', @admin.email))
    assert_equal(0, email_notification_count('user_device_new_location', @admin.email))
    assert_equal(result.class, Array)
    user_device_last = UserDevice.last
    assert_equal(user_device_last.id, user_device_first.id)
    assert_equal(user_device_last.updated_at.to_s, user_device_first.updated_at.to_s)

    user_device_last.updated_at = Time.zone.now - 4.hours
    user_device_last.save!

    params = {}
    get '/api/v1/users', params, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)

    Scheduler.worker(true)

    assert_equal(5, UserDevice.where(user_id: @admin.id).count)
    assert_equal(1, email_notification_count('user_device_new', @admin.email))
    assert_equal(0, email_notification_count('user_device_new_location', @admin.email))
    assert_equal(result.class, Array)
    user_device_last = UserDevice.last
    assert_equal(user_device_last.id, user_device_first.id)
    assert(user_device_last.updated_at > user_device_first.updated_at)

  end

  test '07 - login index with admin with basic auth' do

    ENV['HTTP_USER_AGENT'] = 'curl 1.2.3'
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('user-device-admin', 'adminpw')

    params = {}
    get '/api/v1/users', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)

    Scheduler.worker(true)

    assert_equal(5, UserDevice.where(user_id: @admin.id).count)
    assert_equal(0, email_notification_count('user_device_new', @admin.email))
    assert_equal(0, email_notification_count('user_device_new_location', @admin.email))
    assert_equal(result.class, Array)

  end

  test '08 - login index with agent with basic auth' do

    assert_equal(0, UserDevice.where(user_id: @agent.id).count)
    assert_equal(0, email_notification_count('user_device_new', @agent.email))
    assert_equal(0, email_notification_count('user_device_new_location', @agent.email))

    ENV['HTTP_USER_AGENT'] = 'curl 1.2.3'
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('user-device-agent', 'agentpw')

    params = {}
    get '/api/v1/users', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)

    Scheduler.worker(true)

    assert_equal(1, UserDevice.where(user_id: @agent.id).count)
    assert_equal(0, email_notification_count('user_device_new', @agent.email))
    assert_equal(0, email_notification_count('user_device_new_location', @agent.email))
    assert_equal(result.class, Array)

  end

  test '09 - login index with agent with basic auth' do

    assert_equal(1, UserDevice.where(user_id: @agent.id).count)
    assert_equal(0, email_notification_count('user_device_new', @agent.email))
    assert_equal(0, email_notification_count('user_device_new_location', @agent.email))

    ENV['HTTP_USER_AGENT'] = 'curl 1.2.3'
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('user-device-agent', 'agentpw')

    params = {}
    get '/api/v1/users', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)

    Scheduler.worker(true)

    assert_equal(1, UserDevice.where(user_id: @agent.id).count)
    assert_equal(0, email_notification_count('user_device_new', @agent.email))
    assert_equal(0, email_notification_count('user_device_new_location', @agent.email))
    assert_equal(result.class, Array)

  end

  test '10 - login with switched_from_user_id' do

    assert_equal(1, UserDevice.where(user_id: @agent.id).count)
    assert_equal(0, email_notification_count('user_device_new', @agent.email))
    assert_equal(0, email_notification_count('user_device_new_location', @agent.email))

    ENV['SWITCHED_FROM_USER_ID'] = @admin.id.to_s

    params = { fingerprint: 'my_finger_print_II', username: 'user-device-agent', password: 'agentpw' }
    post '/api/v1/signin', params.to_json, @headers
    assert_response(201)
    result = JSON.parse(@response.body)

    Scheduler.worker(true)

    assert_equal(1, UserDevice.where(user_id: @agent.id).count)
    assert_equal(0, email_notification_count('user_device_new', @agent.email))
    assert_equal(0, email_notification_count('user_device_new_location', @agent.email))
    assert_equal(result.class, Hash)
    assert_not(result['error'])
    assert(result['config'])
    assert('my_finger_print_II', controller.session[:user_device_fingerprint])

    Scheduler.worker(true)

    assert_equal(1, UserDevice.where(user_id: @agent.id).count)
    assert_equal(0, email_notification_count('user_device_new', @agent.email))
    assert_equal(0, email_notification_count('user_device_new_location', @agent.email))

    ENV['USER_DEVICE_UPDATED_AT'] = (Time.zone.now - 4.hours).to_s
    params = {}
    get '/api/v1/users', params.to_json, @headers
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Array)
    assert('my_finger_print_II', controller.session[:user_device_fingerprint])

    Scheduler.worker(true)

    assert_equal(1, UserDevice.where(user_id: @agent.id).count)
    assert_equal(0, email_notification_count('user_device_new', @agent.email))
    assert_equal(0, email_notification_count('user_device_new_location', @agent.email))
    ENV['USER_DEVICE_UPDATED_AT'] = nil

    ENV['TEST_REMOTE_IP'] = '195.65.29.254' # ch
    params = {}
    get '/api/v1/users', params.to_json, @headers
    assert_response(200)
    result = JSON.parse(@response.body)

    Scheduler.worker(true)

    # ip reset
    ENV['TEST_REMOTE_IP'] = '5.9.62.170' # de

    assert_equal(1, UserDevice.where(user_id: @agent.id).count)
    assert_equal(0, email_notification_count('user_device_new', @agent.email))
    assert_equal(0, email_notification_count('user_device_new_location', @agent.email))

  end
end
