# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Integration Placetel', type: :request do

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
      mobile:    '+01114100300',
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

    Setting.set('placetel_integration', true)
    Setting.set('placetel_config', {
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
                    notify_user_ids:  {
                      2 => true,
                      4 => false,
                    },
                  }
                })

    Cti::CallerId.rebuild
  end

  describe 'request handling' do

    it 'does token check' do
      params = 'event=IncomingCall&from=01114100300&to=030600000000&call_id=4991155921769858278-1'
      post '/api/v1/placetel/not_existing_token', params: params
      expect(response).to have_http_status(:unauthorized)

      error = nil
      local_response = REXML::Document.new(response.body)
      local_response.elements.each('Response/Error') do |element|
        error = element.text
      end
      expect(error).to eq('Invalid token, please contact your admin!')
    end

    it 'does basic call' do
      token = Setting.get('placetel_token')

      # inbound - I
      params = 'event=IncomingCall&from=01114100300&to=030600000000&call_id=4991155921769858278-1'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)

      local_response = REXML::Document.new(response.body)
      expect(local_response.elements.count).to eq(1)
      expect(local_response.elements.first.to_s).to eq('<Response/>')

      # inbound - II - block caller
      params = 'event=IncomingCall&from=491715000000&to=030600000000&call_id=4991155921769858278-2'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)

      local_response = REXML::Document.new(response.body)
      reason = nil
      local_response.elements.each('Response/Reject') do |element|
        reason = element.attributes['reason']
      end
      expect(reason).to eq('busy')

      # outbound - I - set default_caller_id
      params = 'event=OutgoingCall&direction=out&from=030600000000&to=01114100300&call_id=8621106404543334274-3'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)

      caller_id = nil
      number_to_dail = nil
      lcoal_response = REXML::Document.new(response.body)
      lcoal_response.elements.each('Response/Dial') do |element|
        caller_id = element.attributes['callerId']
      end
      lcoal_response.elements.each('Response/Dial/Number') do |element|
        number_to_dail = element.text
      end
      expect(caller_id).to eq('4930777000000')
      expect(number_to_dail).to eq('01114100300')

      # outbound - II - set caller_id based on routing_table by explicite number
      params = 'event=OutgoingCall&direction=out&from=030600000000&to=491714000000&call_id=8621106404543334274-4'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)

      caller_id = nil
      number_to_dail = nil
      lcoal_response = REXML::Document.new(response.body)
      lcoal_response.elements.each('Response/Dial') do |element|
        caller_id = element.attributes['callerId']
      end
      lcoal_response.elements.each('Response/Dial/Number') do |element|
        number_to_dail = element.text
      end
      expect(caller_id).to eq('41715880339000')
      expect(number_to_dail).to eq('491714000000')

      # outbound - III - set caller_id based on routing_table by 41*
      params = 'event=OutgoingCall&direction=out&from=030600000000&to=4147110000000&call_id=8621106404543334274-5'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)

      caller_id = nil
      number_to_dail = nil
      lcoal_response = REXML::Document.new(response.body)
      lcoal_response.elements.each('Response/Dial') do |element|
        caller_id = element.attributes['callerId']
      end
      lcoal_response.elements.each('Response/Dial/Number') do |element|
        number_to_dail = element.text
      end
      expect(caller_id).to eq('41715880339000')
      expect(number_to_dail).to eq('4147110000000')

      # no config
      Setting.set('placetel_config', {})
      params = 'event=IncomingCall&from=01114100300&to=030600000000&call_id=4991155921769858278-6'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:unprocessable_entity)

      error = nil
      local_response = REXML::Document.new(response.body)
      local_response.elements.each('Response/Error') do |element|
        error = element.text
      end
      expect(error).to eq('Feature not configured, please contact your admin!')
    end

    it 'does log call' do
      token = Setting.get('placetel_token')

      # outbound - I - new call
      params = 'event=OutgoingCall&direction=out&from=030600000000&to=01114100300&call_id=1234567890-1'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-1')
      expect(log).to be_truthy
      expect(log.from).to eq('4930777000000')
      expect(log.to).to eq('01114100300')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to be_nil
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('newCall')
      expect(log.done).to be(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      travel 1.second

      # outbound - I - hangup by agent
      params = 'event=HungUp&call_id=1234567890-1&type=missed'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-1')
      expect(log).to be_truthy
      expect(log.from).to eq('4930777000000')
      expect(log.to).to eq('01114100300')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to be_nil
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to eq('cancel')
      expect(log.state).to eq('hangup')
      expect(log.done).to be(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_truthy
      expect(log.duration_waiting_time).to be_truthy
      expect(log.duration_talking_time).to be_nil

      travel 1.second

      # outbound - II - new call
      params = 'event=OutgoingCall&direction=out&from=030600000000&to=01114100300&call_id=1234567890-2'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-2')
      expect(log).to be_truthy
      expect(log.from).to eq('4930777000000')
      expect(log.to).to eq('01114100300')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to be_nil
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('newCall')
      expect(log.done).to be(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      travel 1.second

      # outbound - II - answer by customer
      params = 'event=CallAccepted&call_id=1234567890-2&from=030600000000&to=01114100300'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-2')
      expect(log).to be_truthy
      expect(log.from).to eq('4930777000000')
      expect(log.to).to eq('01114100300')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to be_nil
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('answer')
      expect(log.done).to be(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_truthy
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_truthy
      expect(log.duration_talking_time).to be_nil

      travel 1.second

      # outbound - II - hangup by customer
      params = 'event=HungUp&call_id=1234567890-2&type=accepted&from=030600000000&to=01114100300'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-2')
      expect(log).to be_truthy
      expect(log.from).to eq('4930777000000')
      expect(log.to).to eq('01114100300')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to be_nil
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to eq('normalClearing')
      expect(log.state).to eq('hangup')
      expect(log.done).to be(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_truthy
      expect(log.end_at).to be_truthy
      expect(log.duration_waiting_time).to be_truthy
      expect(log.duration_talking_time).to be_truthy

      travel 1.second

      # inbound - I - new call
      params = 'event=IncomingCall&to=030600000000&from=01114100300&call_id=1234567890-3'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-3')
      expect(log).to be_truthy
      expect(log.to).to eq('030600000000')
      expect(log.from).to eq('01114100300')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to be_nil
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('newCall')
      expect(log.done).to be(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      travel 1.second

      # inbound - I - answer by customer
      params = 'event=CallAccepted&call_id=1234567890-3&to=030600000000&from=01114100300'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-3')
      expect(log).to be_truthy
      expect(log.to).to eq('030600000000')
      expect(log.from).to eq('01114100300')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to be_nil
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('answer')
      expect(log.done).to be(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_truthy
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_truthy
      expect(log.duration_talking_time).to be_nil

      travel 1.second

      # inbound - I - hangup by customer
      params = 'event=HungUp&call_id=1234567890-3&type=accepted&to=030600000000&from=01114100300'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-3')
      expect(log).to be_truthy
      expect(log.to).to eq('030600000000')
      expect(log.from).to eq('01114100300')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to be_nil
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to eq('normalClearing')
      expect(log.state).to eq('hangup')
      expect(log.done).to be(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_truthy
      expect(log.end_at).to be_truthy
      expect(log.duration_waiting_time).to be_truthy
      expect(log.duration_talking_time).to be_truthy

      travel 1.second

      # inbound - II - new call
      params = 'event=IncomingCall&to=030600000000&from=01114100300&call_id=1234567890-4'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-4')
      expect(log).to be_truthy
      expect(log.to).to eq('030600000000')
      expect(log.from).to eq('01114100300')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to be_nil
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('newCall')
      expect(log.done).to be(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      travel 1.second

      # inbound - II - answer by voicemail
      params = 'event=CallAccepted&call_id=1234567890-4&to=030600000000&from=01114100300&user=voicemail'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-4')
      expect(log).to be_truthy
      expect(log.to).to eq('030600000000')
      expect(log.from).to eq('01114100300')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('voicemail')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('answer')
      expect(log.done).to be(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_truthy
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_truthy
      expect(log.duration_talking_time).to be_nil

      travel 1.second

      # inbound - II - hangup by customer
      params = 'event=HungUp&call_id=1234567890-4&type=accepted&to=030600000000&from=01114100300'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-4')
      expect(log).to be_truthy
      expect(log.to).to eq('030600000000')
      expect(log.from).to eq('01114100300')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('voicemail')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to eq('normalClearing')
      expect(log.state).to eq('hangup')
      expect(log.done).to be(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_truthy
      expect(log.end_at).to be_truthy
      expect(log.duration_waiting_time).to be_truthy
      expect(log.duration_talking_time).to be_truthy

      travel 1.second

      # inbound - III - new call
      params = 'event=IncomingCall&to=030600000000&from=01114100300&call_id=1234567890-5'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-5')
      expect(log).to be_truthy
      expect(log.to).to eq('030600000000')
      expect(log.from).to eq('01114100300')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to be_nil
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('newCall')
      expect(log.done).to be(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      travel 1.second

      # inbound - III - hangup by customer
      params = 'event=HungUp&call_id=1234567890-5&type=accepted&to=030600000000&from=01114100300'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-5')
      expect(log).to be_truthy
      expect(log.to).to eq('030600000000')
      expect(log.from).to eq('01114100300')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to be_nil
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to eq('normalClearing')
      expect(log.state).to eq('hangup')
      expect(log.done).to be(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_truthy
      expect(log.duration_waiting_time).to be_truthy
      expect(log.duration_talking_time).to be_nil

      travel 1.second

      # inbound - IV - new call
      params = 'event=IncomingCall&to=030600000000&from=49999992222222&call_id=1234567890-6'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-6')
      expect(log).to be_truthy
      expect(log.to).to eq('030600000000')
      expect(log.from).to eq('49999992222222')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to be_nil
      expect(log.from_comment).to eq('CallerId Customer3,CallerId Customer2')
      expect(log.preferences['to']).to be_falsey
      expect(log.preferences['from']).to be_truthy
      expect(log.comment).to be_nil
      expect(log.state).to eq('newCall')
      expect(log.done).to be(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      travel 1.second

      # inbound - IV - new call
      params = 'event=IncomingCall&to=030600000000&from=anonymous&call_id=1234567890-7'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-7')
      expect(log).to be_truthy
      expect(log.to).to eq('030600000000')
      expect(log.from).to eq('anonymous')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to be_nil
      expect(log.from_comment).to be_nil
      expect(log.preferences['to']).to be_falsey
      expect(log.preferences['from']).to be_falsey
      expect(log.comment).to be_nil
      expect(log.state).to eq('newCall')
      expect(log.done).to be(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      # get caller list
      get '/api/v1/cti/log'
      expect(response).to have_http_status(:forbidden)

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
      expect(json_response['list'][5]['from_comment']).to be_nil
      expect(json_response['list'][5]['to']).to eq('01114100300')
      expect(json_response['list'][5]['to_comment']).to eq('CallerId Customer1')
      expect(json_response['list'][5]['comment']).to eq('normalClearing')
      expect(json_response['list'][5]['state']).to eq('hangup')
      expect(json_response['list'][6]['call_id']).to eq('1234567890-1')
    end

    it 'does log call with peer' do
      token = Setting.get('placetel_token')

      # outbound - I - new call
      params = 'event=OutgoingCall&direction=out&from=030600000000&to=01114100300&call_id=1234567890-1&peer=something@example.com'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-1')
      expect(log).to be_truthy
      expect(log.from).to eq('4930777000000')
      expect(log.to).to eq('01114100300')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to be_nil
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('newCall')
      expect(log.done).to be(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      config = Setting.get('placetel_config')
      config[:api_token] = '123'
      config[:outbound][:default_caller_id] = ''
      Setting.set('placetel_config', config)

      stub_request(:get, 'https://api.placetel.de/v2/sip_users')
        .to_return(status: 200, body: [{ 'callerid' => '03055571600', 'did' => 10, 'name' => 'Bob Smith', 'type' => 'standard', 'sipuid' => '777008478072@example.com' }, { 'callerid' => '03055571600', 'did' => 12, 'name' => 'Josef Müller', 'type' => 'standard', 'sipuid' => '777042617425@example.com' }].to_json)

      params = 'event=OutgoingCall&direction=out&to=099999222222&call_id=1234567890-2&from=777008478072@example.com'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-2')
      expect(log).to be_truthy
      expect(log.from).to eq('777008478072@example.com')
      expect(log.to).to eq('099999222222')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to eq('Bob Smith')
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('newCall')
      expect(log.done).to be(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      # check if cache is filled
      expect(Rails.cache.read('placetelGetVoipUsers')['777008478072@example.com']).to eq('Bob Smith')

      params = 'event=IncomingCall&direction=in&to=030600000000&from=012345&call_id=1234567890-3&peer=777008478072@example.com'
      post "/api/v1/placetel/#{token}", params: params
      expect(response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-3')
      expect(log).to be_truthy
      expect(log.from).to eq('012345')
      expect(log.to).to eq('030600000000')
      expect(log.direction).to eq('in')
      expect(log.from_comment).to be_nil
      expect(log.to_comment).to eq('Bob Smith')
      expect(log.comment).to be_nil
      expect(log.state).to eq('newCall')
      expect(log.done).to be(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      # check if cache is filled
      expect(Rails.cache.read('placetelGetVoipUsers')['777008478072@example.com']).to eq('Bob Smith')
    end
  end
end
