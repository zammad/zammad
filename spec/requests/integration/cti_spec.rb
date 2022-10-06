# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Integration CTI', type: :request do

  let(:agent) do
    create(:agent)
  end
  let!(:customer1) do
    create(
      :customer,
      login:     'ticket-caller_id_cti-customer1@example.com',
      firstname: 'CallerId',
      lastname:  'Customer1',
      phone:     '+49 99999 222222',
      fax:       '+49 99999 222223',
      mobile:    '+4912347114711',
      note:      'Phone at home: +49 99999 222224',
    )
  end
  let!(:customer2) do
    create(
      :customer,
      login:     'ticket-caller_id_cti-customer2@example.com',
      firstname: 'CallerId',
      lastname:  'Customer2',
      phone:     '+49 99999 222222 2',
    )
  end
  let!(:customer3) do
    create(
      :customer,
      login:     'ticket-caller_id_cti-customer3@example.com',
      firstname: 'CallerId',
      lastname:  'Customer3',
      phone:     '+49 99999 222222 2',
    )
  end

  before do
    Cti::Log.destroy_all

    Setting.set('cti_integration', true)
    Setting.set('cti_config', {
                  outbound: {
                    routing_table:     [
                      {
                        dest:      '41*',
                        caller_id: '41715880339000',
                      },
                      {
                        dest:      '491714000000',
                        caller_id: '41715880339000',
                      },
                    ],
                    default_caller_id: '4930777000000',
                  },
                  inbound:  {
                    block_caller_ids: [
                      {
                        caller_id: '491715000000',
                        note:      'some note',
                      }
                    ],
                  }
                })

    Cti::CallerId.rebuild
  end

  describe 'request handling' do
    let!(:token) { Setting.get('cti_token') }

    it 'does token check' do
      post '/api/v1/cti/not_existing_token', params: {
        event:     'newCall',
        direction: 'in',
        from:      '4912347114711',
        to:        '4930600000000',
        call_id:   '4991155921769858278-1',
        user:      'user 1',
      }
      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Invalid token, please contact your admin!')
    end

    it 'does basic call' do

      # inbound - I
      post "/api/v1/cti/#{token}", params: {
        event:     'newCall',
        direction: 'in',
        from:      '4912347114711',
        to:        '4930600000000',
        call_id:   '4991155921769858278-1',
        user:      ['user+1', 'user+2'],
      }
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a(Hash)
      expect(json_response).to be_blank

      # inbound - II - block caller
      post "/api/v1/cti/#{token}", params: {
        event:     'newCall',
        direction: 'in',
        from:      '491715000000',
        to:        '4930600000000',
        call_id:   '4991155921769858278-2',
        user:      ['user+1', 'user+2'],
      }
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a(Hash)
      expect(json_response['action']).to eq('reject')
      expect(json_response['reason']).to eq('busy')

      # outbound - I - set default_caller_id
      post "/api/v1/cti/#{token}", params: {
        event:     'newCall',
        direction: 'out',
        from:      '4930600000000',
        to:        '4912347114711',
        call_id:   '8621106404543334274-3',
        user:      'user 1',
      }
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['action']).to eq('dial')
      expect(json_response['number']).to eq('4912347114711')
      expect(json_response['caller_id']).to eq('4930777000000')

      # outbound - II - set caller_id based on routing_table by explicite number
      post "/api/v1/cti/#{token}", params: {
        event:     'newCall',
        direction: 'out',
        from:      '4930600000000',
        to:        '491714000000',
        call_id:   '8621106404543334274-4',
        user:      'user 1',
      }
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['action']).to eq('dial')
      expect(json_response['number']).to eq('491714000000')
      expect(json_response['caller_id']).to eq('41715880339000')

      # outbound - III - set caller_id based on routing_table by 41*
      post "/api/v1/cti/#{token}", params: {
        event:     'newCall',
        direction: 'out',
        from:      '4930600000000',
        to:        '4147110000000',
        call_id:   '8621106404543334274-5',
        user:      'user 1',
      }
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['action']).to eq('dial')
      expect(json_response['number']).to eq('4147110000000')
      expect(json_response['caller_id']).to eq('41715880339000')

      # no config
      Setting.set('cti_config', {})
      post "/api/v1/cti/#{token}", params: {
        event:     'newCall',
        direction: 'in',
        from:      '4912347114711',
        to:        '4930600000000',
        call_id:   '4991155921769858278-6',
        user:      ['user+1', 'user+2'],

      }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Feature not configured, please contact your admin!')

    end

    it 'does log call' do

      # outbound - I - new call
      post "/api/v1/cti/#{token}", params: {
        event:     'newCall',
        direction: 'out',
        from:      '4930600000000',
        to:        '4912347114711',
        call_id:   '1234567890-1',
        user:      'user 1',
      }
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-1')
      expect(log).to be_truthy
      expect(log.from).to eq('4930777000000')
      expect(log.to).to eq('4912347114711')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to eq('user 1')
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.queue).to eq('4930777000000')
      expect(log.state).to eq('newCall')
      expect(log.done).to be(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      travel 2.seconds

      # outbound - I - hangup by agent
      post "/api/v1/cti/#{token}", params: {
        event:     'hangup',
        direction: 'out',
        call_id:   '1234567890-1',
        cause:     'cancel',
      }
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-1')
      expect(log).to be_truthy
      expect(log.from).to eq('4930777000000')
      expect(log.to).to eq('4912347114711')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to eq('user 1')
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to eq('cancel')
      expect(log.queue).to eq('4930777000000')
      expect(log.state).to eq('hangup')
      expect(log.done).to be(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_truthy
      expect(log.duration_waiting_time).to be_between(2, 3)
      expect(log.duration_talking_time).to be_nil

      # outbound - II - new call
      post "/api/v1/cti/#{token}", params: {
        event:     'newCall',
        direction: 'out',
        from:      '4930600000000',
        to:        '4912347114711',
        call_id:   '1234567890-2',
        user:      ['user 1'],
      }
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-2')
      expect(log).to be_truthy
      expect(log.from).to eq('4930777000000')
      expect(log.to).to eq('4912347114711')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to eq('user 1')
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.queue).to eq('4930777000000')
      expect(log.state).to eq('newCall')
      expect(log.done).to be(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      travel 2.seconds

      # outbound - II - answer by customer
      post "/api/v1/cti/#{token}", params: {
        event:     'answer',
        direction: 'out',
        call_id:   '1234567890-2',
        from:      '4930600000000',
        to:        '4912347114711',
      }
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-2')
      expect(log).to be_truthy
      expect(log.from).to eq('4930777000000')
      expect(log.to).to eq('4912347114711')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to eq('user 1')
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.queue).to eq('4930777000000')
      expect(log.state).to eq('answer')
      expect(log.done).to be(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_truthy
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_between(2, 3)
      expect(log.duration_talking_time).to be_nil

      travel 2.seconds

      # outbound - II - hangup by customer
      post "/api/v1/cti/#{token}", params: {
        event:     'hangup',
        direction: 'out',
        call_id:   '1234567890-2',
        cause:     'normalClearing',
        from:      '4930600000000',
        to:        '4912347114711',
      }
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-2')
      expect(log).to be_truthy
      expect(log.from).to eq('4930777000000')
      expect(log.to).to eq('4912347114711')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to eq('user 1')
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to eq('normalClearing')
      expect(log.queue).to eq('4930777000000')
      expect(log.state).to eq('hangup')
      expect(log.done).to be(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_truthy
      expect(log.end_at).to be_truthy
      expect(log.duration_waiting_time).to be_between(2, 3)
      expect(log.duration_talking_time).to be_between(2, 3)

      travel 1.second

      # inbound - I - new call
      post "/api/v1/cti/#{token}", params: {
        event:     'newCall',
        direction: 'in',
        to:        '4930600000000',
        from:      '4912347114711',
        call_id:   '1234567890-3',
        user:      'user 1',
      }
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-3')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('user 1')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.queue).to eq('4930600000000')
      expect(log.state).to eq('newCall')
      expect(log.done).to be(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      travel 1.second

      # inbound - I - answer by customer
      post "/api/v1/cti/#{token}", params: {
        event:     'answer',
        direction: 'in',
        call_id:   '1234567890-3',
        to:        '4930600000000',
        from:      '4912347114711',
      }
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-3')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('user 1')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.queue).to eq('4930600000000')
      expect(log.state).to eq('answer')
      expect(log.done).to be(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_truthy
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_truthy
      expect(log.duration_talking_time).to be_nil

      travel 1.second

      # inbound - I - hangup by customer
      post "/api/v1/cti/#{token}", params: {
        event:     'hangup',
        direction: 'in',
        call_id:   '1234567890-3',
        cause:     'normalClearing',
        to:        '4930600000000',
        from:      '4912347114711',
      }
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-3')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('user 1')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to eq('normalClearing')
      expect(log.queue).to eq('4930600000000')
      expect(log.state).to eq('hangup')
      expect(log.done).to be(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_truthy
      expect(log.end_at).to be_truthy
      expect(log.duration_waiting_time).to be_truthy
      expect(log.duration_talking_time).to be_truthy

      travel 1.second

      # inbound - I - answer for hangup by customer
      post "/api/v1/cti/#{token}", params: {
        event:     'answer',
        direction: 'in',
        call_id:   '1234567890-3',
        to:        '4930600000000',
        from:      '4912347114711',
      }, as: :json
      expect(response).to have_http_status(:ok)

      travel 1.second

      # inbound - II - new call
      post "/api/v1/cti/#{token}", params: {
        event:     'newCall',
        direction: 'in',
        to:        '4930600000000',
        from:      '4912347114711',
        call_id:   '1234567890-4',
        user:      ['user 1', 'user 2'],
      }
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-4')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('user 1, user 2')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.queue).to eq('4930600000000')
      expect(log.state).to eq('newCall')
      expect(log.done).to be(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      travel 1.second

      # inbound - II - answer by voicemail
      post "/api/v1/cti/#{token}", params: {
        event:     'answer',
        direction: 'in',
        call_id:   '1234567890-4',
        to:        '4930600000000',
        from:      '4912347114711',
        user:      'voicemail',
      }
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-4')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('voicemail')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.queue).to eq('4930600000000')
      expect(log.state).to eq('answer')
      expect(log.done).to be(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_truthy
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_truthy
      expect(log.duration_talking_time).to be_nil

      travel 1.second

      # inbound - II - hangup by customer
      post "/api/v1/cti/#{token}", params: {
        event:     'hangup',
        direction: 'in',
        call_id:   '1234567890-4',
        cause:     'normalClearing',
        to:        '4930600000000',
        from:      '4912347114711',
      }
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-4')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('voicemail')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to eq('normalClearing')
      expect(log.queue).to eq('4930600000000')
      expect(log.state).to eq('hangup')
      expect(log.done).to be(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_truthy
      expect(log.end_at).to be_truthy
      expect(log.duration_waiting_time).to be_truthy
      expect(log.duration_talking_time).to be_truthy

      travel 1.second

      # inbound - III - new call
      post "/api/v1/cti/#{token}", params: {
        event:     'newCall',
        direction: 'in',
        to:        '4930600000000',
        from:      '4912347114711',
        call_id:   '1234567890-5',
        user:      'user 1,user 2',
      }
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-5')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('user 1,user 2')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.queue).to eq('4930600000000')
      expect(log.state).to eq('newCall')
      expect(log.done).to be(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      travel 1.second

      # inbound - III - hangup by customer
      post "/api/v1/cti/#{token}", params: {
        event:     'hangup',
        direction: 'in',
        call_id:   '1234567890-5',
        cause:     'normalClearing',
        to:        '4930600000000',
        from:      '4912347114711',
      }
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-5')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('user 1,user 2')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to eq('normalClearing')
      expect(log.queue).to eq('4930600000000')
      expect(log.state).to eq('hangup')
      expect(log.done).to be(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_truthy
      expect(log.duration_waiting_time).to be_truthy
      expect(log.duration_talking_time).to be_nil

      travel 1.second

      # inbound - IV - new call
      post "/api/v1/cti/#{token}", params: {
        event:     'newCall',
        direction: 'in',
        to:        '4930600000000',
        from:      '49999992222222',
        call_id:   '1234567890-6',
        user:      'user 1,user 2',
      }
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-6')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('49999992222222')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('user 1,user 2')
      expect(log.from_comment).to eq('CallerId Customer3,CallerId Customer2')
      expect(log.preferences['to']).to be_falsey
      expect(log.preferences['from']).to be_truthy
      expect(log.comment).to be_nil
      expect(log.queue).to eq('4930600000000')
      expect(log.state).to eq('newCall')
      expect(log.done).to be(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      travel 1.second

      # inbound - IV - new call
      post "/api/v1/cti/#{token}", params: {
        event:     'newCall',
        direction: 'in',
        to:        '4930600000000',
        from:      'anonymous',
        call_id:   '1234567890-7',
        user:      'user 1,user 2',
        queue:     'some_queue_name',
      }
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-7')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('anonymous')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('user 1,user 2')
      expect(log.from_comment).to be_nil
      expect(log.preferences['to']).to be_falsey
      expect(log.preferences['from']).to be_falsey
      expect(log.comment).to be_nil
      expect(log.queue).to eq('some_queue_name')
      expect(log.state).to eq('newCall')
      expect(log.done).to be(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      get '/api/v1/cti/log'
      expect(response).to have_http_status(:forbidden)

      # get caller list
      authenticated_as(agent)
      get '/api/v1/cti/log', as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['list']).to be_a(Array)
      expect(json_response['list'].count).to eq(7)
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['User']).to be_truthy
      expect(json_response['assets']['User'][customer2.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][customer3.id.to_s]).to be_truthy
      expect(json_response['list'][0]['call_id']).to eq('1234567890-7')
      expect(json_response['list'][1]['call_id']).to eq('1234567890-6')
      expect(json_response['list'][2]['call_id']).to eq('1234567890-5')
      expect(json_response['list'][3]['call_id']).to eq('1234567890-4')
      expect(json_response['list'][4]['call_id']).to eq('1234567890-3')
      expect(json_response['list'][5]['call_id']).to eq('1234567890-2')
      expect(json_response['list'][5]['state']).to eq('hangup')
      expect(json_response['list'][5]['from']).to eq('4930777000000')
      expect(json_response['list'][5]['from_comment']).to eq('user 1')
      expect(json_response['list'][5]['to']).to eq('4912347114711')
      expect(json_response['list'][5]['to_comment']).to eq('CallerId Customer1')
      expect(json_response['list'][5]['comment']).to eq('normalClearing')
      expect(json_response['list'][5]['state']).to eq('hangup')
      expect(json_response['list'][6]['call_id']).to eq('1234567890-1')
    end

    it 'does log call with notify group with two a log entry' do

      # outbound - I - new call
      post "/api/v1/cti/#{token}", params: {
        event:     'newCall',
        direction: 'out',
        from:      '4930600000000',
        to:        '4912347114711',
        call_id:   '1234567890-1',
        user:      'user 1',
      }
      expect(response).to have_http_status(:ok)

      # outbound - II - new call
      post "/api/v1/cti/#{token}", params: {
        event:     'newCall',
        direction: 'out',
        from:      '4930600000000',
        to:        '4912347114711',
        call_id:   '1234567890-2',
        user:      'user 1',
      }

      # inbound - III - new call
      post "/api/v1/cti/#{token}", params: {
        event:     'newCall',
        direction: 'in',
        to:        '4930600000000',
        from:      '4912347114711',
        call_id:   '1234567890-5',
        user:      'user 1,user 2',
      }
      expect(response).to have_http_status(:ok)

      # get caller list (with notify group with 2 log entries)
      cti_config = Setting.get('cti_config')
      cti_config[:notify_map] = [{ queue: '4930777000000', user_ids: [agent.id.to_s] }]
      Setting.set('cti_config', cti_config)

      authenticated_as(agent)
      get '/api/v1/cti/log', as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response.dig('assets', 'User')).not_to be_nil
      expect(json_response['list'].map { |x| x['call_id'] }).to match_array(%w[1234567890-1 1234567890-2])
    end

    it 'does log call with notify group without a log entry' do

      # outbound - I - new call
      post "/api/v1/cti/#{token}", params: {
        event:     'newCall',
        direction: 'out',
        from:      '4930600000000',
        to:        '4912347114711',
        call_id:   '1234567890-1',
        user:      'user 1',
      }
      expect(response).to have_http_status(:ok)

      # outbound - II - new call
      post "/api/v1/cti/#{token}", params: {
        event:     'newCall',
        direction: 'out',
        from:      '4930600000000',
        to:        '4912347114711',
        call_id:   '1234567890-2',
        user:      'user 1',
      }

      # inbound - III - new call
      post "/api/v1/cti/#{token}", params: {
        event:     'newCall',
        direction: 'in',
        to:        '4930600000000',
        from:      '4912347114711',
        call_id:   '1234567890-5',
        user:      'user 1,user 2',
      }
      expect(response).to have_http_status(:ok)

      # get caller list (with notify group without a log entry)
      cti_config = Setting.get('cti_config')
      cti_config[:notify_map] = [{ queue: '4912347114711', user_ids: [agent.to_s] }]
      Setting.set('cti_config', cti_config)

      authenticated_as(agent)
      get '/api/v1/cti/log', as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['list']).to eq([])
    end

    it 'does queue param tests' do

      # inbound - queue & user
      post "/api/v1/cti/#{token}", params: {
        event:     'newCall',
        direction: 'in',
        to:        '4930600000000',
        from:      'anonymous',
        call_id:   '1234567890-1',
        user:      'user 1,user 2',
        queue:     'some_queue_name',
      }
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-1')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('anonymous')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('user 1,user 2')
      expect(log.from_comment).to be_nil
      expect(log.preferences['to']).to be_falsey
      expect(log.preferences['from']).to be_falsey
      expect(log.comment).to be_nil
      expect(log.queue).to eq('some_queue_name')
      expect(log.state).to eq('newCall')
      expect(log.done).to be(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      # inbound - queue & no user
      post "/api/v1/cti/#{token}", params: {
        event:     'newCall',
        direction: 'in',
        to:        '4930600000000',
        from:      'anonymous',
        call_id:   '1234567890-2',
        user:      '',
        queue:     'some_queue_name',
      }
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-2')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('anonymous')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('some_queue_name')
      expect(log.from_comment).to be_nil
      expect(log.preferences['to']).to be_falsey
      expect(log.preferences['from']).to be_falsey
      expect(log.comment).to be_nil
      expect(log.queue).to eq('some_queue_name')
      expect(log.state).to eq('newCall')
      expect(log.done).to be(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

    end

    it 'flags caller_log as done' do

      cti_log1 = create(:cti_log)
      log = Cti::Log.find(cti_log1.id)
      expect(log.done).to be(false)

      authenticated_as(agent)
      post "/api/v1/cti/done/#{cti_log1.id}", params: {
        done: true
      }
      expect(response).to have_http_status(:ok)

      log = Cti::Log.find(cti_log1.id)
      expect(log.done).to be(true)
    end

    it 'flags all caller_logs as done via done_bulk' do

      cti_log1 = create(:cti_log)
      cti_log2 = create(:cti_log)

      log = Cti::Log.find(cti_log1.id)
      expect(log.done).to be(false)

      authenticated_as(agent)
      post '/api/v1/cti/done/bulk', params: {
        ids: [cti_log1.id, cti_log2.id]
      }

      expect(response).to have_http_status(:ok)
      log1 = Cti::Log.find(cti_log1.id)
      expect(log1.done).to be(true)

      log2 = Cti::Log.find(cti_log2.id)
      expect(log2.done).to be(true)
    end
  end
end
