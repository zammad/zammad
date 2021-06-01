# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Monitoring', type: :request do

  let!(:admin) do
    create(:admin, groups: Group.all)
  end
  let!(:agent) do
    create(:agent, groups: Group.all)
  end
  let!(:customer) do
    create(:customer)
  end
  let!(:token) do
    SecureRandom.urlsafe_base64(64)
  end

  before do
    Setting.set('monitoring_token', token)

    # channel cleanup
    Channel.where.not(area: 'Email::Notification').destroy_all
    Channel.all.each do |channel|
      channel.status_in  = 'ok'
      channel.status_out = 'ok'
      channel.last_log_in = nil
      channel.last_log_out = nil
      channel.save!
    end
    dir = Rails.root.join('tmp/unprocessable_mail')
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
  end

  describe 'request handling' do

    it 'does monitoring without token' do

      # health_check
      get '/api/v1/monitoring/health_check', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['healthy']).to be_falsey
      expect(json_response['error']).to eq('Not authorized')

      # status
      get '/api/v1/monitoring/status', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['agents']).to be_falsey
      expect(json_response['last_login']).to be_falsey
      expect(json_response['counts']).to be_falsey
      expect(json_response['last_created_at']).to be_falsey
      expect(json_response['error']).to eq('Not authorized')

      # token
      post '/api/v1/monitoring/token', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['token']).to be_falsey
      expect(json_response['error']).to eq('Authentication required')

    end

    it 'does monitoring with wrong token' do

      # health_check
      get '/api/v1/monitoring/health_check?token=abc', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['healthy']).to be_falsey
      expect(json_response['error']).to eq('Not authorized')

      # status
      get '/api/v1/monitoring/status?token=abc', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['agents']).to be_falsey
      expect(json_response['last_login']).to be_falsey
      expect(json_response['counts']).to be_falsey
      expect(json_response['last_created_at']).to be_falsey
      expect(json_response['error']).to eq('Not authorized')

      # token
      post '/api/v1/monitoring/token', params: { token: 'abc' }, as: :json
      expect(response).to have_http_status(:forbidden)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['token']).to be_falsey
      expect(json_response['error']).to eq('Authentication required')

    end

    it 'does monitoring with correct token' do

      # test storage usage
      string = ''
      1000.times do
        string += 'Some Text Some Text Some Text Some Text Some Text Some Text Some Text Some Text'
      end

      Store.add(
        object:        'User',
        o_id:          1,
        data:          string,
        filename:      'filename.txt',
        created_by_id: 1,
      )

      # health_check
      get "/api/v1/monitoring/health_check?token=#{token}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to be_falsey
      expect(json_response['issues']).to eq([])
      expect(json_response['healthy']).to eq(true)
      expect(json_response['message']).to eq('success')

      # status
      get "/api/v1/monitoring/status?token=#{token}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to be_falsey
      expect(json_response).to be_key('agents')
      expect(json_response).to be_key('last_login')
      expect(json_response).to be_key('counts')
      expect(json_response).to be_key('last_created_at')

      first_json_response_kb = 0
      if ActiveRecord::Base.connection_config[:adapter] == 'postgresql'
        expect(json_response['storage']).to be_truthy
        expect(json_response['storage']).to be_key('kB')
        expect(json_response['storage']['kB']).to be > 0
        expect(json_response['storage']).to be_key('MB')
        expect(json_response['storage']).to be_key('GB')

        first_json_response_kb = json_response['storage']['kB']
      else
        expect(json_response['storage']).to be_falsey
      end

      # save same file again
      Store.add(
        object:        'User',
        o_id:          1,
        data:          string,
        filename:      'filename.txt',
        created_by_id: 1,
      )

      # status
      get "/api/v1/monitoring/status?token=#{token}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to be_falsey
      expect(json_response).to be_key('agents')
      expect(json_response).to be_key('last_login')
      expect(json_response).to be_key('counts')
      expect(json_response).to be_key('last_created_at')

      if ActiveRecord::Base.connection_config[:adapter] == 'postgresql'
        expect(json_response['storage']).to be_truthy
        expect(json_response['storage']).to be_key('kB')

        # check if the stores got summarized.
        expect(json_response['storage']['kB']).to eq(first_json_response_kb * 2)
        expect(json_response['storage']).to be_key('MB')
        expect(json_response['storage']).to be_key('GB')
      else
        expect(json_response['storage']).to be_falsey
      end

      Store.add(
        object:        'User',
        o_id:          1,
        data:          "#{string}123",
        filename:      'filename2.txt',
        created_by_id: 1,
      )

      # status
      get "/api/v1/monitoring/status?token=#{token}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to be_falsey
      expect(json_response).to be_key('agents')
      expect(json_response).to be_key('last_login')
      expect(json_response).to be_key('counts')
      expect(json_response).to be_key('last_created_at')

      if ActiveRecord::Base.connection_config[:adapter] == 'postgresql'
        expect(json_response['storage']).to be_truthy
        expect(json_response['storage']).to be_key('kB')

        # check if the stores got summarized. value should be greather than the size of just one file (saved 2 times)
        expect(json_response['storage']['kB']).to be > first_json_response_kb
        expect(json_response['storage']).to be_key('MB')
        expect(json_response['storage']).to be_key('GB')
      else
        expect(json_response['storage']).to be_falsey
      end

      # token
      post '/api/v1/monitoring/token', params: { token: token }, as: :json
      expect(response).to have_http_status(:forbidden)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['token']).to be_falsey
      expect(json_response['error']).to eq('Authentication required')

    end

    it 'does monitoring with admin user' do

      # health_check
      authenticated_as(admin)
      get '/api/v1/monitoring/health_check', params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to be_falsey
      expect(json_response['healthy']).to eq(true)
      expect(json_response['message']).to eq('success')

      # status
      get '/api/v1/monitoring/status', params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to be_falsey
      expect(json_response).to be_key('agents')
      expect(json_response).to be_key('last_login')
      expect(json_response).to be_key('counts')
      expect(json_response).to be_key('last_created_at')

      # token
      post '/api/v1/monitoring/token', params: { token: token }, as: :json
      expect(response).to have_http_status(:created)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['token']).to be_truthy
      expect(json_response['error']).to be_falsey

    end

    it 'does monitoring with agent user' do

      # health_check
      authenticated_as(agent)
      get '/api/v1/monitoring/health_check', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['healthy']).to be_falsey
      expect(json_response['error']).to eq('Not authorized (user)!')

      # status
      get '/api/v1/monitoring/status', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['agents']).to be_falsey
      expect(json_response['last_login']).to be_falsey
      expect(json_response['counts']).to be_falsey
      expect(json_response['last_created_at']).to be_falsey
      expect(json_response['error']).to eq('Not authorized (user)!')

      # token
      post '/api/v1/monitoring/token', params: { token: token }, as: :json
      expect(response).to have_http_status(:forbidden)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['token']).to be_falsey
      expect(json_response['error']).to eq('Not authorized (user)!')

    end

    it 'does monitoring with admin user and invalid permission' do

      permission = Permission.find_by(name: 'admin.monitoring')
      permission.active = false
      permission.save!

      # health_check
      authenticated_as(admin)
      get '/api/v1/monitoring/health_check', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['healthy']).to be_falsey
      expect(json_response['error']).to eq('Not authorized (user)!')

      # status
      get '/api/v1/monitoring/status', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['agents']).to be_falsey
      expect(json_response['last_login']).to be_falsey
      expect(json_response['counts']).to be_falsey
      expect(json_response['last_created_at']).to be_falsey
      expect(json_response['error']).to eq('Not authorized (user)!')

      # token
      post '/api/v1/monitoring/token', params: { token: token }, as: :json
      expect(response).to have_http_status(:forbidden)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['token']).to be_falsey
      expect(json_response['error']).to eq('Not authorized (user)!')

      permission.active = true
      permission.save!
    end

    it 'does monitoring with correct token and invalid permission' do

      permission = Permission.find_by(name: 'admin.monitoring')
      permission.active = false
      permission.save!

      # health_check
      get "/api/v1/monitoring/health_check?token=#{token}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to be_falsey
      expect(json_response['healthy']).to eq(true)
      expect(json_response['message']).to eq('success')

      # status
      get "/api/v1/monitoring/status?token=#{token}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to be_falsey
      expect(json_response).to be_key('agents')
      expect(json_response).to be_key('last_login')
      expect(json_response).to be_key('counts')
      expect(json_response).to be_key('last_created_at')

      # token
      post '/api/v1/monitoring/token', params: { token: token }, as: :json
      expect(response).to have_http_status(:forbidden)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['token']).to be_falsey
      expect(json_response['error']).to eq('Authentication required')

      permission.active = true
      permission.save!

    end

    it 'does check health false' do
      channel = Channel.find_by(active: true)
      channel.status_in  = 'ok'
      channel.status_out = 'error'
      channel.last_log_in = nil
      channel.last_log_out = nil
      channel.save!

      # health_check - channel
      get "/api/v1/monitoring/health_check?token=#{token}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['message']).to be_truthy
      expect(json_response['issues']).to be_truthy
      expect(json_response['healthy']).to eq(false)
      expect(json_response['message']).to eq('Channel: Email::Notification out  ')

      # health_check - scheduler may not run
      scheduler = Scheduler.where(active: true).last
      scheduler.last_run = Time.zone.now - 20.minutes
      scheduler.period = 600
      scheduler.save!

      get "/api/v1/monitoring/health_check?token=#{token}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['message']).to be_truthy
      expect(json_response['issues']).to be_truthy
      expect(json_response['healthy']).to eq(false)
      expect(json_response['message']).to eq("Channel: Email::Notification out  ;scheduler may not run (last execution of #{scheduler.method} 10 minutes over) - please contact your system administrator")

      # health_check - scheduler may not run
      scheduler = Scheduler.where(active: true).last
      scheduler.last_run = Time.zone.now - 1.day
      scheduler.period = 600
      scheduler.save!

      get "/api/v1/monitoring/health_check?token=#{token}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['message']).to be_truthy
      expect(json_response['issues']).to be_truthy
      expect(json_response['healthy']).to eq(false)
      expect(json_response['message']).to eq("Channel: Email::Notification out  ;scheduler may not run (last execution of #{scheduler.method} about 24 hours over) - please contact your system administrator")

      # health_check - scheduler job count
      travel 2.seconds
      8001.times do |fake_ticket_id|
        SearchIndexJob.perform_later('Ticket', fake_ticket_id)
      end
      Scheduler.where(active: true).each do |local_scheduler|
        local_scheduler.last_run = Time.zone.now
        local_scheduler.save!
      end
      total_jobs = Delayed::Job.count

      get "/api/v1/monitoring/health_check?token=#{token}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['message']).to be_truthy
      expect(json_response['issues']).to be_truthy
      expect(json_response['healthy']).to eq(false)
      expect(json_response['message']).to eq('Channel: Email::Notification out  ')

      travel 20.minutes
      Scheduler.where(active: true).each do |local_scheduler|
        local_scheduler.last_run = Time.zone.now
        local_scheduler.save!
      end

      get "/api/v1/monitoring/health_check?token=#{token}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['message']).to be_truthy
      expect(json_response['issues']).to be_truthy
      expect(json_response['healthy']).to eq(false)
      expect(json_response['message']).to eq("Channel: Email::Notification out  ;#{total_jobs} background jobs in queue")

      Delayed::Job.delete_all
      travel_back

      # health_check - unprocessable mail
      dir = Rails.root.join('tmp/unprocessable_mail')
      FileUtils.mkdir_p(dir)
      FileUtils.touch("#{dir}/test.eml")

      get "/api/v1/monitoring/health_check?token=#{token}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['message']).to be_truthy
      expect(json_response['issues']).to be_truthy
      expect(json_response['healthy']).to eq(false)
      expect(json_response['message']).to eq('Channel: Email::Notification out  ;unprocessable mails: 1')

      # health_check - ldap
      Setting.set('ldap_integration', true)
      ImportJob.create(
        name:        'Import::Ldap',
        started_at:  Time.zone.now,
        finished_at: Time.zone.now,
        result:      {
          error: 'Some bad error'
        }
      )

      get "/api/v1/monitoring/health_check?token=#{token}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['message']).to be_truthy
      expect(json_response['issues']).to be_truthy
      expect(json_response['healthy']).to eq(false)
      expect(json_response['message']).to eq("Channel: Email::Notification out  ;unprocessable mails: 1;Failed to run import backend 'Import::Ldap'. Cause: Some bad error")

      stuck_updated_at_timestamp = 15.minutes.ago
      ImportJob.create(
        name:        'Import::Ldap',
        started_at:  Time.zone.now,
        finished_at: nil,
        updated_at:  stuck_updated_at_timestamp,
      )

      # health_check
      get "/api/v1/monitoring/health_check?token=#{token}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['message']).to be_truthy
      expect(json_response['issues']).to be_truthy
      expect(json_response['healthy']).to eq(false)
      expect(json_response['message']).to eq("Channel: Email::Notification out  ;unprocessable mails: 1;Failed to run import backend 'Import::Ldap'. Cause: Some bad error;Stuck import backend 'Import::Ldap' detected. Last update: #{stuck_updated_at_timestamp}")

      privacy_stuck_updated_at_timestamp = 30.minutes.ago
      task = create(:data_privacy_task, deletable: customer)
      task.update(updated_at: privacy_stuck_updated_at_timestamp)

      # health_check
      get "/api/v1/monitoring/health_check?token=#{token}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['message']).to be_truthy
      expect(json_response['issues']).to be_truthy
      expect(json_response['healthy']).to eq(false)
      expect(json_response['message']).to eq("Channel: Email::Notification out  ;unprocessable mails: 1;Failed to run import backend 'Import::Ldap'. Cause: Some bad error;Stuck import backend 'Import::Ldap' detected. Last update: #{stuck_updated_at_timestamp};Stuck data privacy task (ID #{task.id}) detected. Last update: #{privacy_stuck_updated_at_timestamp}")

      Setting.set('ldap_integration', false)
    end

    it 'does check restart_failed_jobs' do
      authenticated_as(admin)
      post '/api/v1/monitoring/restart_failed_jobs', params: {}, as: :json
      expect(response).to have_http_status(:ok)
    end

    it 'does check failed delayed job', db_strategy: :reset do
      # disable elasticsearch
      prev_es_config = Setting.get('es_url')
      Setting.set('es_url', 'http://127.0.0.1:92001')

      # delete all background jobs created while seeding
      # to have a clean state for checking for failed ones
      Delayed::Job.destroy_all

      # add a new object
      object = create(:object_manager_attribute_text, name: 'test4')

      migration = ObjectManager::Attribute.migration_execute
      expect(true).to eq(migration)

      authenticated_as(admin)
      post "/api/v1/object_manager_attributes/#{object.id}", params: {}, as: :json
      token = @response.headers['CSRF-TOKEN']

      # parameters for updating
      params = {
        name:        'test4',
        object:      'Ticket',
        display:     'Test 4',
        active:      true,
        data_type:   'input',
        data_option: {
          default:   'test',
          type:      'text',
          maxlength: 120
        },
        screens:     {
          create_middle: {
            'ticket.customer': {
              shown:      true,
              item_class: 'column'
            },
            'ticket.agent':    {
              shown:      true,
              item_class: 'column'
            }
          },
          edit:          {
            'ticket.customer': {
              shown: true
            },
            'ticket.agent':    {
              shown: true
            }
          }
        },
        id:          'c-196'
      }

      # update the object
      put "/api/v1/object_manager_attributes/#{object.id}", params: params, as: :json

      migration = ObjectManager::Attribute.migration_execute
      expect(true).to eq(migration)

      expect(response).to have_http_status(:ok)
      expect(json_response).to be_truthy
      expect(json_response['data_option']['null']).to be_truthy
      expect('test4').to eq(json_response['name'])
      expect('Test 4').to eq(json_response['display'])

      4.times do
        Delayed::Worker.new.work_off
      end

      # health_check
      get "/api/v1/monitoring/health_check?token=#{token}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['message']).to be_truthy
      expect(json_response['issues']).to be_truthy
      expect(json_response['healthy']).to eq(false)
      expect( json_response['message']).to eq("Failed to run background job #1 'SearchIndexAssociationsJob' 1 time(s) with 1 attempt(s).")

      # add another job
      manual_added = SearchIndexJob.perform_later('Ticket', 1)
      Delayed::Job.find(manual_added.provider_job_id).update!(attempts: 10)

      # health_check
      get "/api/v1/monitoring/health_check?token=#{token}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['message']).to be_truthy
      expect(json_response['issues']).to be_truthy
      expect(json_response['healthy']).to eq(false)
      expect( json_response['message']).to eq("Failed to run background job #1 'SearchIndexAssociationsJob' 1 time(s) with 1 attempt(s).;Failed to run background job #2 'SearchIndexJob' 1 time(s) with 10 attempt(s).")

      # add another job
      dummy_class = Class.new(ApplicationJob) do

        def perform
          puts 'work work'
        end
      end

      manual_added = Delayed::Job.enqueue( dummy_class.new )
      manual_added.update!(attempts: 5)

      # health_check
      get "/api/v1/monitoring/health_check?token=#{token}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['message']).to be_truthy
      expect(json_response['issues']).to be_truthy
      expect(json_response['healthy']).to eq(false)
      expect(json_response['message']).to eq("Failed to run background job #1 'Object' 1 time(s) with 5 attempt(s).;Failed to run background job #2 'SearchIndexAssociationsJob' 1 time(s) with 1 attempt(s).;Failed to run background job #3 'SearchIndexJob' 1 time(s) with 10 attempt(s).")

      # reset settings
      Setting.set('es_url', prev_es_config)

      # add some more failing job
      10.times do
        manual_added = Delayed::Job.enqueue( dummy_class.new )
        manual_added.update!(attempts: 5)
      end

      # health_check
      get "/api/v1/monitoring/health_check?token=#{token}", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['message']).to be_truthy
      expect(json_response['issues']).to be_truthy
      expect(json_response['healthy']).to eq(false)
      expect(json_response['message']).to eq("13 failing background jobs;Failed to run background job #1 'Object' 8 time(s) with 40 attempt(s).;Failed to run background job #2 'SearchIndexAssociationsJob' 1 time(s) with 1 attempt(s).;Failed to run background job #3 'SearchIndexJob' 1 time(s) with 10 attempt(s).")

      # cleanup
      Delayed::Job.delete_all
    end

    it 'does check amount' do
      Ticket.destroy_all

      # amount_check - ok
      get "/api/v1/monitoring/amount_check?token=#{token}&periode=1h", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response.key?('state')).to eq(false)
      expect(json_response.key?('message')).to eq(false)
      expect(json_response['count']).to eq(0)

      Ticket.destroy_all
      (1..6).each do |i|
        create(:ticket, title: "Ticket-#{i}")
        travel 10.seconds
      end

      get "/api/v1/monitoring/amount_check?token=#{token}&periode=1h&min_warning=10&min_critical=8", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state']).to eq('critical')
      expect(json_response['message']).to eq('The minimum of 8 was undercut by 6 in the last 1h')
      expect(json_response['count']).to eq(6)

      get "/api/v1/monitoring/amount_check?token=#{token}&periode=1h&min_warning=7&min_critical=2", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state']).to eq('warning')
      expect(json_response['message']).to eq('The minimum of 7 was undercut by 6 in the last 1h')
      expect(json_response['count']).to eq(6)

      get "/api/v1/monitoring/amount_check?token=#{token}&periode=1h&max_warning=10&max_critical=20", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state']).to eq('ok')
      expect(json_response.key?('message')).to eq(false)
      expect(json_response['count']).to eq(6)

      (1..6).each do |i|
        create(:ticket, title: "Ticket-#{i}")
        travel 1.second
      end

      get "/api/v1/monitoring/amount_check?token=#{token}&periode=1h&max_warning=10&max_critical=20", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state']).to eq('warning')
      expect(json_response['message']).to eq('The limit of 10 was exceeded with 12 in the last 1h')
      expect(json_response['count']).to eq(12)

      (1..10).each do |i|
        create(:ticket, title: "Ticket-#{i}")
        travel 1.second
      end

      get "/api/v1/monitoring/amount_check?token=#{token}&periode=1h&max_warning=10&max_critical=20", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state']).to eq('critical')
      expect(json_response['message']).to eq('The limit of 20 was exceeded with 22 in the last 1h')
      expect(json_response['count']).to eq(22)

      get "/api/v1/monitoring/amount_check?token=#{token}&periode=1h&max_warning=30", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state']).to eq('ok')
      expect(json_response.key?('message')).to eq(false)
      expect(json_response['count']).to eq(22)

      get "/api/v1/monitoring/amount_check?token=#{token}&periode=1h", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response.key?('state')).to eq(false)
      expect(json_response.key?('message')).to eq(false)
      expect(json_response['count']).to eq(22)

      travel 2.hours

      get "/api/v1/monitoring/amount_check?token=#{token}&periode=1h&max_warning=30", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['state']).to eq('ok')
      expect(json_response.key?('message')).to eq(false)
      expect(json_response['count']).to eq(0)

      get "/api/v1/monitoring/amount_check?token=#{token}&periode=1h", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response.key?('state')).to eq(false)
      expect(json_response.key?('message')).to eq(false)
      expect(json_response['count']).to eq(0)
    end
  end
end
