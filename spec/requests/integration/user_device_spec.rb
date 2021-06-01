# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'User Device', type: :request, sends_notification_emails: true do

  let!(:admin) do
    create(:admin, login: 'user-device-admin', password: 'adminpw', groups: Group.all)
  end
  let!(:agent) do
    create(:agent, login: 'user-device-agent', password: 'agentpw', groups: Group.all)
  end

  before do
    ENV['TEST_REMOTE_IP'] = '5.9.62.170' # de
    ENV['HTTP_USER_AGENT'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11; rv:46.0) Gecko/20100101 Firefox/46.0'
    ENV['SWITCHED_FROM_USER_ID'] = nil

    UserDevice.destroy_all
  end

  describe 'request handling' do

    it 'does index with nobody (01)' do

      get '/api/v1/signshow'
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect('no valid session').to eq(json_response['error'])
      expect(json_response['config']).to be_truthy
      expect(controller.session[:user_device_fingerprint]).to be_falsey

      Scheduler.worker(true)
    end

    it 'does login index with admin without fingerprint (02)' do

      params = { without_fingerprint: 'none', username: 'user-device-admin', password: 'adminpw' }
      post '/api/v1/signin', params: params, as: :json
      expect(response).to have_http_status(:unprocessable_entity)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Need fingerprint param!')
      expect(json_response['config']).to be_falsey
      expect(controller.session[:user_device_fingerprint]).to be_falsey

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     admin,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     admin,
        )
      end

      expect(UserDevice.where(user_id: admin.id).count).to eq(0)
    end

    it 'does login index with admin with fingerprint - I (03)' do
      params = { fingerprint: 'my_finger_print', username: 'user-device-admin', password: 'adminpw' }
      post '/api/v1/signin', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to be_falsey
      expect(json_response['config']).to be_truthy
      expect(controller.session[:user_device_fingerprint]).to eq('my_finger_print')

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     admin,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     admin,
        )
      end

      expect(UserDevice.where(user_id: admin.id).count).to eq(1)
      user_device_first = UserDevice.last
      sleep 2

      params = {}
      get '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(controller.session[:user_device_fingerprint]).to eq('my_finger_print')

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     admin,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     admin,
        )
      end

      expect(UserDevice.where(user_id: admin.id).count).to eq(1)
      user_device_last = UserDevice.last
      expect(user_device_first.updated_at.to_s).to eq(user_device_last.updated_at.to_s)

      params = { fingerprint: 'my_finger_print' }
      get '/api/v1/signshow', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['session']).to be_truthy
      expect('user-device-admin').to eq(json_response['session']['login'])
      expect(json_response['config']).to be_truthy

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     admin,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     admin,
        )
      end

      expect(UserDevice.where(user_id: admin.id).count).to eq(1)
      user_device_last = UserDevice.last
      expect(user_device_first.updated_at.to_s).to eq(user_device_last.updated_at.to_s)

      ENV['USER_DEVICE_UPDATED_AT'] = (Time.zone.now - 4.hours).to_s
      params = {}
      get '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(controller.session[:user_device_fingerprint]).to eq('my_finger_print')

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     admin,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     admin,
        )
      end

      expect(UserDevice.where(user_id: admin.id).count).to eq(1)
      user_device_last = UserDevice.last
      expect(user_device_last.updated_at.to_s).not_to eq(user_device_first.updated_at.to_s)
      ENV['USER_DEVICE_UPDATED_AT'] = nil

      ENV['TEST_REMOTE_IP'] = '195.65.29.254' # ch

      #reset_notification_checks

      params = {}
      get '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:ok)

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     admin,
        )
        sent(
          template: 'user_device_new_location',
          user:     admin,
        )
      end

      expect(UserDevice.where(user_id: admin.id).count).to eq(2)

      # ip reset
      ENV['TEST_REMOTE_IP'] = '5.9.62.170' # de

    end

    it 'does login index with admin with fingerprint - II (04)' do

      create(
        :user_device,
        user_id:     admin.id,
        fingerprint: 'fingerprintI',
      )

      params = { fingerprint: 'my_finger_print_II', username: 'user-device-admin', password: 'adminpw' }
      post '/api/v1/signin', params: params, as: :json
      expect(response).to have_http_status(:created)

      check_notification do

        Scheduler.worker(true)

        sent(
          template: 'user_device_new',
          user:     admin,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     admin,
        )
      end

      expect(UserDevice.where(user_id: admin.id).count).to eq(2)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to be_falsey
      expect(json_response['config']).to be_truthy
      expect(controller.session[:user_device_fingerprint]).to be_truthy

      get '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     admin,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     admin,
        )
      end

      expect(UserDevice.where(user_id: admin.id).count).to eq(2)

      params = { fingerprint: 'my_finger_print_II' }
      get '/api/v1/signshow', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['session']).to be_truthy
      expect('user-device-admin').to eq(json_response['session']['login'])
      expect(json_response['config']).to be_truthy

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     admin,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     admin,
        )
      end

      expect(UserDevice.where(user_id: admin.id).count).to eq(2)

      ENV['TEST_REMOTE_IP'] = '195.65.29.254' # ch

      params = {}
      get '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:ok)

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     admin,
        )
        sent(
          template: 'user_device_new_location',
          user:     admin,
        )
      end

      expect(UserDevice.where(user_id: admin.id).count).to eq(3)

      # ip reset
      ENV['TEST_REMOTE_IP'] = '5.9.62.170' # de
    end

    it 'does login index with admin with fingerprint - II (05)' do

      UserDevice.add(
        ENV['HTTP_USER_AGENT'],
        ENV['TEST_REMOTE_IP'],
        admin.id,
        'my_finger_print_II',
        'session', # session|basic_auth|token_auth|sso
      )

      expect(UserDevice.where(user_id: admin.id).count).to eq(1)

      params = { fingerprint: 'my_finger_print_II', username: 'user-device-admin', password: 'adminpw' }
      post '/api/v1/signin', params: params, as: :json
      expect(response).to have_http_status(:created)

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     admin,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     admin,
        )
      end

      expect(UserDevice.where(user_id: admin.id).count).to eq(1)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to be_falsey
      expect(json_response['config']).to be_truthy
      expect(controller.session[:user_device_fingerprint]).to be_truthy
    end

    it 'does login index with admin with basic auth (06)' do

      ENV['HTTP_USER_AGENT'] = 'curl 1.0.0'
      UserDevice.add(
        ENV['HTTP_USER_AGENT'],
        '127.0.0.1',
        admin.id,
        '',
        'basic_auth', # session|basic_auth|token_auth|sso
      )
      expect(UserDevice.where(user_id: admin.id).count).to eq(1)

      ENV['HTTP_USER_AGENT'] = 'curl 1.2.3'
      params = {}
      authenticated_as(admin, password: 'adminpw')
      get '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:ok)

      check_notification do

        Scheduler.worker(true)

        sent(
          template: 'user_device_new',
          user:     admin,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     admin,
        )
      end

      expect(UserDevice.where(user_id: admin.id).count).to eq(2)
      expect(json_response).to be_a_kind_of(Array)
      user_device_first = UserDevice.last
      sleep 2

      params = {}
      get '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:ok)

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     admin,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     admin,
        )
      end

      expect(UserDevice.where(user_id: admin.id).count).to eq(2)
      expect(json_response).to be_a_kind_of(Array)
      user_device_last = UserDevice.last
      expect(user_device_first.id).to eq(user_device_last.id)
      expect(user_device_first.updated_at.to_s).to eq(user_device_last.updated_at.to_s)

      user_device_last.updated_at = Time.zone.now - 4.hours
      user_device_last.save!

      params = {}
      get '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:ok)

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     admin,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     admin,
        )
      end

      expect(UserDevice.where(user_id: admin.id).count).to eq(2)
      expect(json_response).to be_a_kind_of(Array)
      user_device_last = UserDevice.last
      expect(user_device_first.id).to eq(user_device_last.id)
      expect(user_device_last.updated_at > user_device_first.updated_at).to be_truthy
    end

    it 'does login index with admin with basic auth (07)' do

      ENV['HTTP_USER_AGENT'] = 'curl 1.2.3'

      UserDevice.add(
        ENV['HTTP_USER_AGENT'],
        ENV['TEST_REMOTE_IP'],
        admin.id,
        '',
        'basic_auth', # session|basic_auth|token_auth|sso
      )

      expect(UserDevice.where(user_id: admin.id).count).to eq(1)

      params = {}
      authenticated_as(admin, password: 'adminpw')
      get '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:ok)

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     admin,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     admin,
        )
      end

      expect(UserDevice.where(user_id: admin.id).count).to eq(1)
      expect(json_response).to be_a_kind_of(Array)

    end

    it 'does login index with agent with basic auth (08)' do
      ENV['HTTP_USER_AGENT'] = 'curl 1.2.3'

      params = {}
      authenticated_as(agent, password: 'agentpw')
      get '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:ok)

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     agent,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     agent,
        )
      end

      expect(UserDevice.where(user_id: agent.id).count).to eq(1)
      expect(json_response).to be_a_kind_of(Array)
    end

    it 'does login index with agent with basic auth (09)' do

      ENV['HTTP_USER_AGENT'] = 'curl 1.2.3'

      UserDevice.add(
        ENV['HTTP_USER_AGENT'],
        ENV['TEST_REMOTE_IP'],
        agent.id,
        '',
        'basic_auth', # session|basic_auth|token_auth|sso
      )

      expect(UserDevice.where(user_id: agent.id).count).to eq(1)

      params = {}
      authenticated_as(agent, password: 'agentpw')
      get '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:ok)

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     agent,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     agent,
        )
      end

      expect(UserDevice.where(user_id: agent.id).count).to eq(1)
      expect(json_response).to be_a_kind_of(Array)

    end

    it 'does login with switched_from_user_id (10)' do
      expect(UserDevice.where(user_id: agent.id).count).to eq(0)

      ENV['SWITCHED_FROM_USER_ID'] = admin.id.to_s

      params = { fingerprint: 'my_finger_print_II', username: 'user-device-agent', password: 'agentpw' }
      post '/api/v1/signin', params: params, as: :json
      expect(response).to have_http_status(:created)

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     agent,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     agent,
        )
      end

      expect(UserDevice.where(user_id: agent.id).count).to eq(0)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to be_falsey
      expect(json_response['config']).to be_truthy

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     agent,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     agent,
        )
      end

      expect(UserDevice.where(user_id: agent.id).count).to eq(0)

      ENV['USER_DEVICE_UPDATED_AT'] = (Time.zone.now - 4.hours).to_s
      params = {}
      get '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     agent,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     agent,
        )
      end

      expect(UserDevice.where(user_id: agent.id).count).to eq(0)
      ENV['USER_DEVICE_UPDATED_AT'] = nil

      ENV['TEST_REMOTE_IP'] = '195.65.29.254' # ch
      params = {}
      get '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:ok)

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     agent,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     agent,
        )
      end

      # ip reset
      ENV['TEST_REMOTE_IP'] = '5.9.62.170' # de

      expect(UserDevice.where(user_id: agent.id).count).to eq(0)
    end

    it 'does login with invalid fingerprint (11)' do
      params = { fingerprint: 'to_long_1234567890to_long_1234567890to_long_1234567890to_long_1234567890to_long_1234567890to_long_1234567890to_long_1234567890to_long_1234567890to_long_1234567890to_long_1234567890to_long_1234567890', username: 'user-device-admin', password: 'adminpw' }
      post '/api/v1/signin', params: params, as: :json
      expect(response).to have_http_status(:unprocessable_entity)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('fingerprint is 198 chars but can only be 160 chars!')
      expect(json_response['config']).to be_falsey
      expect(controller.session[:user_device_fingerprint]).to be_falsey

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     admin,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     admin,
        )
      end

      expect(UserDevice.where(user_id: admin.id).count).to eq(0)
    end

    it 'does login with integer as fingerprint (12)' do
      params = { fingerprint: 123_456_789, username: 'user-device-admin', password: 'adminpw' }
      post '/api/v1/signin', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(controller.session[:user_device_fingerprint]).to be_truthy

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     admin,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     admin,
        )
      end

      expect(UserDevice.where(user_id: admin.id).count).to eq(1)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to be_nil
    end

    it 'does login form controller - check no user device logging (13)' do
      Setting.set('form_ticket_create', true)

      params = {
        fingerprint: 'long_1234567890long_1234567890long_1234567890long_1234567890long_1234567890long_1234567890long_1234567890long_1234567890long_1234567890long_1234567890long_1234567890'
      }
      authenticated_as(admin, password: 'adminpw')
      post '/api/v1/form_config', params: params, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to be_falsey
      expect(json_response['endpoint']).to be_truthy
      expect(controller.session[:user_device_fingerprint]).to be_falsey

      check_notification do

        Scheduler.worker(true)

        not_sent(
          template: 'user_device_new',
          user:     admin,
        )
        not_sent(
          template: 'user_device_new_location',
          user:     admin,
        )
      end

      expect(UserDevice.where(user_id: admin.id).count).to eq(0)
    end
  end
end
