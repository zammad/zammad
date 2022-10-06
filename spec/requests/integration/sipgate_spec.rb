# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Integration Sipgate', type: :request do

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

    Setting.set('sipgate_integration', true)
    Setting.set('sipgate_config', {
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
                },)

    Cti::CallerId.rebuild
  end

  describe 'request handling' do
    it 'does token check' do
      params = 'event=newCall&direction=in&from=4912347114711&to=4930600000000&callId=4991155921769858278-1&user%5B%5D=user+1&user%5B%5D=user+2'
      post '/api/v1/sipgate/not_existing_token/in', params: params
      expect(response).to have_http_status(:unauthorized)

      error = nil
      local_response = REXML::Document.new(response.body)
      local_response.elements.each('Response/Error') do |element|
        error = element.text
      end
      expect(error).to eq('Invalid token, please contact your admin!')
    end

    it 'does basic call' do
      token = Setting.get('sipgate_token')

      # inbound - I
      params = 'event=newCall&direction=in&from=4912347114711&to=4930600000000&callId=4991155921769858278-1&user%5B%5D=user+1&user%5B%5D=user+2'
      post "/api/v1/sipgate/#{token}/in", params: params
      expect(@response).to have_http_status(:ok)
      on_hangup = nil
      on_answer = nil
      content = @response.body
      response = REXML::Document.new(content)
      response.elements.each('Response') do |element|
        on_hangup = element.attributes['onHangup']
        on_answer = element.attributes['onAnswer']
      end
      expect(on_hangup).to eq("http://zammad.example.com/api/v1/sipgate/#{token}/in")
      expect(on_answer).to eq("http://zammad.example.com/api/v1/sipgate/#{token}/in")

      # inbound - II - block caller
      params = 'event=newCall&direction=in&from=491715000000&to=4930600000000&callId=4991155921769858278-2&user%5B%5D=user+1&user%5B%5D=user+2'
      post "/api/v1/sipgate/#{token}/in", params: params
      expect(@response).to have_http_status(:ok)
      on_hangup = nil
      on_answer = nil
      content = @response.body
      response = REXML::Document.new(content)
      response.elements.each('Response') do |element|
        on_hangup = element.attributes['onHangup']
        on_answer = element.attributes['onAnswer']
      end
      expect(on_hangup).to eq("http://zammad.example.com/api/v1/sipgate/#{token}/in")
      expect(on_answer).to eq("http://zammad.example.com/api/v1/sipgate/#{token}/in")
      reason = nil
      response.elements.each('Response/Reject') do |element|
        reason = element.attributes['reason']
      end
      expect(reason).to eq('busy')

      # outbound - I - set default_caller_id
      params = 'event=newCall&direction=out&from=4930600000000&to=4912347114711&callId=8621106404543334274-3&user%5B%5D=user+1'
      post "/api/v1/sipgate/#{token}/out", params: params
      expect(@response).to have_http_status(:ok)
      on_hangup = nil
      on_answer = nil
      caller_id = nil
      number_to_dail = nil
      content = @response.body
      response = REXML::Document.new(content)
      response.elements.each('Response') do |element|
        on_hangup = element.attributes['onHangup']
        on_answer = element.attributes['onAnswer']
      end
      response.elements.each('Response/Dial') do |element|
        caller_id = element.attributes['callerId']
      end
      response.elements.each('Response/Dial/Number') do |element|
        number_to_dail = element.text
      end
      expect(caller_id).to eq('4930777000000')
      expect(number_to_dail).to eq('4912347114711')
      expect(on_hangup).to eq("http://zammad.example.com/api/v1/sipgate/#{token}/out")
      expect(on_answer).to eq("http://zammad.example.com/api/v1/sipgate/#{token}/out")

      # outbound - II - set caller_id based on routing_table by explicite number
      params = 'event=newCall&direction=out&from=4930600000000&to=491714000000&callId=8621106404543334274-4&user%5B%5D=user+1'
      post "/api/v1/sipgate/#{token}/out", params: params
      expect(@response).to have_http_status(:ok)
      on_hangup = nil
      on_answer = nil
      caller_id = nil
      number_to_dail = nil
      content = @response.body
      response = REXML::Document.new(content)
      response.elements.each('Response') do |element|
        on_hangup = element.attributes['onHangup']
        on_answer = element.attributes['onAnswer']
      end
      response.elements.each('Response/Dial') do |element|
        caller_id = element.attributes['callerId']
      end
      response.elements.each('Response/Dial/Number') do |element|
        number_to_dail = element.text
      end
      expect(caller_id).to eq('41715880339000')
      expect(number_to_dail).to eq('491714000000')
      expect(on_hangup).to eq("http://zammad.example.com/api/v1/sipgate/#{token}/out")
      expect(on_answer).to eq("http://zammad.example.com/api/v1/sipgate/#{token}/out")

      # outbound - III - set caller_id based on routing_table by 41*
      params = 'event=newCall&direction=out&from=4930600000000&to=4147110000000&callId=8621106404543334274-5&user%5B%5D=user+1'
      post "/api/v1/sipgate/#{token}/out", params: params
      expect(@response).to have_http_status(:ok)
      on_hangup = nil
      on_answer = nil
      caller_id = nil
      number_to_dail = nil
      content = @response.body
      response = REXML::Document.new(content)
      response.elements.each('Response') do |element|
        on_hangup = element.attributes['onHangup']
        on_answer = element.attributes['onAnswer']
      end
      response.elements.each('Response/Dial') do |element|
        caller_id = element.attributes['callerId']
      end
      response.elements.each('Response/Dial/Number') do |element|
        number_to_dail = element.text
      end
      expect(caller_id).to eq('41715880339000')
      expect(number_to_dail).to eq('4147110000000')
      expect(on_hangup).to eq("http://zammad.example.com/api/v1/sipgate/#{token}/out")
      expect(on_answer).to eq("http://zammad.example.com/api/v1/sipgate/#{token}/out")

      # no config
      Setting.set('sipgate_config', {})
      params = 'event=newCall&direction=in&from=4912347114711&to=4930600000000&callId=4991155921769858278-6&user%5B%5D=user+1&user%5B%5D=user+2'
      post "/api/v1/sipgate/#{token}/in", params: params
      expect(@response).to have_http_status(:unprocessable_entity)
      error = nil
      content = @response.body
      response = REXML::Document.new(content)
      response.elements.each('Response/Error') do |element|
        error = element.text
      end
      expect(error).to eq('Feature not configured, please contact your admin!')

    end

    it 'does log call' do
      token = Setting.get('sipgate_token')

      # outbound - I - new call
      params = 'event=newCall&direction=out&from=4930600000000&to=4912347114711&callId=1234567890-1&user%5B%5D=user+1'
      post "/api/v1/sipgate/#{token}/out", params: params
      expect(@response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-1')
      expect(log).to be_truthy
      expect(log.from).to eq('4930777000000')
      expect(log.to).to eq('4912347114711')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to eq('user 1')
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('newCall')
      expect(log.done).to be(true)

      travel 1.second

      # outbound - I - hangup by agent
      params = 'event=hangup&direction=out&callId=1234567890-1&cause=cancel'
      post "/api/v1/sipgate/#{token}/out", params: params
      expect(@response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-1')
      expect(log).to be_truthy
      expect(log.from).to eq('4930777000000')
      expect(log.to).to eq('4912347114711')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to eq('user 1')
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to eq('cancel')
      expect(log.state).to eq('hangup')
      expect(log.done).to be(true)

      travel 1.second

      # outbound - II - new call
      params = 'event=newCall&direction=out&from=4930600000000&to=4912347114711&callId=1234567890-2&user%5B%5D=user+1'
      post "/api/v1/sipgate/#{token}/out", params: params
      expect(@response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-2')
      expect(log).to be_truthy
      expect(log.from).to eq('4930777000000')
      expect(log.to).to eq('4912347114711')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to eq('user 1')
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('newCall')
      expect(log.done).to be(true)

      travel 1.second

      # outbound - II - answer by customer
      params = 'event=answer&direction=out&callId=1234567890-2&from=4930600000000&to=4912347114711'
      post "/api/v1/sipgate/#{token}/out", params: params
      expect(@response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-2')
      expect(log).to be_truthy
      expect(log.from).to eq('4930777000000')
      expect(log.to).to eq('4912347114711')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to eq('user 1')
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('answer')
      expect(log.done).to be(true)

      travel 1.second

      # outbound - II - hangup by customer
      params = 'event=hangup&direction=out&callId=1234567890-2&cause=normalClearing&from=4930600000000&to=4912347114711'
      post "/api/v1/sipgate/#{token}/out", params: params
      expect(@response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-2')
      expect(log).to be_truthy
      expect(log.from).to eq('4930777000000')
      expect(log.to).to eq('4912347114711')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to eq('user 1')
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to eq('normalClearing')
      expect(log.state).to eq('hangup')
      expect(log.done).to be(true)

      travel 1.second

      # inbound - I - new call
      params = 'event=newCall&direction=in&to=4930600000000&from=4912347114711&callId=1234567890-3&user%5B%5D=user+1'
      post "/api/v1/sipgate/#{token}/in", params: params
      expect(@response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-3')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('user 1')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('newCall')
      expect(log.done).to be(false)

      travel 1.second

      # inbound - I - answer by customer
      params = 'event=answer&direction=in&callId=1234567890-3&to=4930600000000&from=4912347114711'
      post "/api/v1/sipgate/#{token}/in", params: params
      expect(@response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-3')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('user 1')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('answer')
      expect(log.done).to be(true)

      travel 1.second

      # inbound - I - hangup by customer
      params = 'event=hangup&direction=in&callId=1234567890-3&cause=normalClearing&to=4930600000000&from=4912347114711'
      post "/api/v1/sipgate/#{token}/in", params: params
      expect(@response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-3')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('user 1')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to eq('normalClearing')
      expect(log.state).to eq('hangup')
      expect(log.done).to be(true)

      travel 1.second

      # inbound - II - new call
      params = 'event=newCall&direction=in&to=4930600000000&from=4912347114711&callId=1234567890-4&user%5B%5D=user+1,user+2'
      post "/api/v1/sipgate/#{token}/in", params: params
      expect(@response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-4')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('user 1,user 2')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('newCall')
      expect(log.done).to be(false)

      travel 1.second

      # inbound - II - answer by voicemail
      params = 'event=answer&direction=in&callId=1234567890-4&to=4930600000000&from=4912347114711&user=voicemail'
      post "/api/v1/sipgate/#{token}/in", params: params
      expect(@response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-4')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('voicemail')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('answer')
      expect(log.done).to be(true)

      travel 1.second

      # inbound - II - hangup by customer
      params = 'event=hangup&direction=in&callId=1234567890-4&cause=normalClearing&to=4930600000000&from=4912347114711'
      post "/api/v1/sipgate/#{token}/in", params: params
      expect(@response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-4')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('voicemail')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to eq('normalClearing')
      expect(log.state).to eq('hangup')
      expect(log.done).to be(false)

      travel 1.second

      # inbound - III - new call
      params = 'event=newCall&direction=in&to=4930600000000&from=4912347114711&callId=1234567890-5&user%5B%5D=user+1,user+2'
      post "/api/v1/sipgate/#{token}/in", params: params
      expect(@response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-5')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('user 1,user 2')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('newCall')
      expect(log.done).to be(false)

      travel 1.second

      # inbound - III - hangup by customer
      params = 'event=hangup&direction=in&callId=1234567890-5&cause=normalClearing&to=4930600000000&from=4912347114711'
      post "/api/v1/sipgate/#{token}/in", params: params
      expect(@response).to have_http_status(:ok)
      log = Cti::Log.find_by(call_id: '1234567890-5')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('user 1,user 2')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to eq('normalClearing')
      expect(log.state).to eq('hangup')
      expect(log.done).to be(false)

      travel 1.second

      # inbound - IV - new call
      params = 'event=newCall&direction=in&to=4930600000000&from=49999992222222&callId=1234567890-6&user%5B%5D=user+1,user+2'
      post "/api/v1/sipgate/#{token}/in", params: params
      expect(@response).to have_http_status(:ok)
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
      expect(log.state).to eq('newCall')
      expect(log.done).to be(false)

      # get caller list
      get '/api/v1/cti/log'
      expect(@response).to have_http_status(:forbidden)

      authenticated_as(agent)
      get '/api/v1/cti/log', as: :json
      expect(@response).to have_http_status(:ok)
      expect(json_response['list']).to be_a(Array)
      expect(json_response['list'].count).to eq(6)
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['User']).to be_truthy
      expect(json_response['assets']['User'][customer2.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][customer3.id.to_s]).to be_truthy
      expect(json_response['list'][0]['call_id']).to eq('1234567890-6')
      expect(json_response['list'][1]['call_id']).to eq('1234567890-5')
      expect(json_response['list'][2]['call_id']).to eq('1234567890-4')
      expect(json_response['list'][3]['call_id']).to eq('1234567890-3')
      expect(json_response['list'][4]['call_id']).to eq('1234567890-2')
      expect(json_response['list'][4]['state']).to eq('hangup')
      expect(json_response['list'][4]['from']).to eq('4930777000000')
      expect(json_response['list'][4]['from_comment']).to eq('user 1')
      expect(json_response['list'][4]['to']).to eq('4912347114711')
      expect(json_response['list'][4]['to_comment']).to eq('CallerId Customer1')
      expect(json_response['list'][4]['comment']).to eq('normalClearing')
      expect(json_response['list'][4]['state']).to eq('hangup')
      expect(json_response['list'][5]['call_id']).to eq('1234567890-1')
    end

    it 'alternative fqdn' do
      token = Setting.get('sipgate_token')

      Setting.set('sipgate_alternative_fqdn', 'external.host.example.com')

      # inbound - I
      params = 'event=newCall&direction=in&from=4912347114711&to=4930600000000&callId=4991155921769858278-1&user%5B%5D=user+1&user%5B%5D=user+2'
      post "/api/v1/sipgate/#{token}/in", params: params
      expect(@response).to have_http_status(:ok)
      on_hangup = nil
      on_answer = nil
      content = @response.body
      response = REXML::Document.new(content)
      response.elements.each('Response') do |element|
        on_hangup = element.attributes['onHangup']
        on_answer = element.attributes['onAnswer']
      end
      expect(on_hangup).to eq("http://external.host.example.com/api/v1/sipgate/#{token}/in")
      expect(on_answer).to eq("http://external.host.example.com/api/v1/sipgate/#{token}/in")
    end
  end
end
