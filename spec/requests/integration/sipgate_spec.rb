# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
      local_response_xml = REXML::Document.new(response.body)
      local_response_xml.elements.each('Response/Error') do |element|
        error = element.text
      end
      expect(error).to eq('Invalid token, please contact your admin!')
    end

    it 'does basic call' do
      token = Setting.get('sipgate_token')

      # inbound - I
      params = 'event=newCall&direction=in&from=4912347114711&to=4930600000000&callId=4991155921769858278-1&user%5B%5D=user+1&user%5B%5D=user+2'
      post "/api/v1/sipgate/#{token}/in", params: params
      expect(response).to have_http_status(:ok)
      on_hangup = nil
      on_answer = nil
      content = response.body
      response_xml = REXML::Document.new(content)
      response_xml.elements.each('Response') do |element|
        on_hangup = element.attributes['onHangup']
        on_answer = element.attributes['onAnswer']
      end
      expect(on_hangup).to eq("http://zammad.example.com/api/v1/sipgate/#{token}/in")
      expect(on_answer).to eq("http://zammad.example.com/api/v1/sipgate/#{token}/in")

      # inbound - II - block caller
      params = 'event=newCall&direction=in&from=491715000000&to=4930600000000&callId=4991155921769858278-2&user%5B%5D=user+1&user%5B%5D=user+2'
      post "/api/v1/sipgate/#{token}/in", params: params
      expect(response).to have_http_status(:ok)
      on_hangup = nil
      on_answer = nil
      content = response.body
      response_xml = REXML::Document.new(content)
      response_xml.elements.each('Response') do |element|
        on_hangup = element.attributes['onHangup']
        on_answer = element.attributes['onAnswer']
      end
      expect(on_hangup).to eq("http://zammad.example.com/api/v1/sipgate/#{token}/in")
      expect(on_answer).to eq("http://zammad.example.com/api/v1/sipgate/#{token}/in")
      reason = nil
      response_xml.elements.each('Response/Reject') do |element|
        reason = element.attributes['reason']
      end
      expect(reason).to eq('busy')

      # outbound - I - set default_caller_id
      params = 'event=newCall&direction=out&from=4930600000000&to=4912347114711&callId=8621106404543334274-3&user%5B%5D=user+1'
      post "/api/v1/sipgate/#{token}/out", params: params
      expect(response).to have_http_status(:ok)
      on_hangup = nil
      on_answer = nil
      caller_id = nil
      number_to_dail = nil
      content = response.body
      response_xml = REXML::Document.new(content)
      response_xml.elements.each('Response') do |element|
        on_hangup = element.attributes['onHangup']
        on_answer = element.attributes['onAnswer']
      end
      response_xml.elements.each('Response/Dial') do |element|
        caller_id = element.attributes['callerId']
      end
      response_xml.elements.each('Response/Dial/Number') do |element|
        number_to_dail = element.text
      end
      expect(caller_id).to eq('4930777000000')
      expect(number_to_dail).to eq('4912347114711')
      expect(on_hangup).to eq("http://zammad.example.com/api/v1/sipgate/#{token}/out")
      expect(on_answer).to eq("http://zammad.example.com/api/v1/sipgate/#{token}/out")

      # outbound - II - set caller_id based on routing_table by explicite number
      params = 'event=newCall&direction=out&from=4930600000000&to=491714000000&callId=8621106404543334274-4&user%5B%5D=user+1'
      post "/api/v1/sipgate/#{token}/out", params: params
      expect(response).to have_http_status(:ok)
      on_hangup = nil
      on_answer = nil
      caller_id = nil
      number_to_dail = nil
      content = response.body
      response_xml = REXML::Document.new(content)
      response_xml.elements.each('Response') do |element|
        on_hangup = element.attributes['onHangup']
        on_answer = element.attributes['onAnswer']
      end
      response_xml.elements.each('Response/Dial') do |element|
        caller_id = element.attributes['callerId']
      end
      response_xml.elements.each('Response/Dial/Number') do |element|
        number_to_dail = element.text
      end
      expect(caller_id).to eq('41715880339000')
      expect(number_to_dail).to eq('491714000000')
      expect(on_hangup).to eq("http://zammad.example.com/api/v1/sipgate/#{token}/out")
      expect(on_answer).to eq("http://zammad.example.com/api/v1/sipgate/#{token}/out")

      # outbound - III - set caller_id based on routing_table by 41*
      params = 'event=newCall&direction=out&from=4930600000000&to=4147110000000&callId=8621106404543334274-5&user%5B%5D=user+1'
      post "/api/v1/sipgate/#{token}/out", params: params
      expect(response).to have_http_status(:ok)
      on_hangup = nil
      on_answer = nil
      caller_id = nil
      number_to_dail = nil
      content = response.body
      response_xml = REXML::Document.new(content)
      response_xml.elements.each('Response') do |element|
        on_hangup = element.attributes['onHangup']
        on_answer = element.attributes['onAnswer']
      end
      response_xml.elements.each('Response/Dial') do |element|
        caller_id = element.attributes['callerId']
      end
      response_xml.elements.each('Response/Dial/Number') do |element|
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
      expect(response).to have_http_status(:unprocessable_content)
      error = nil
      content = response.body
      response_xml = REXML::Document.new(content)
      response_xml.elements.each('Response/Error') do |element|
        error = element.text
      end
      expect(error).to eq('Feature not configured, please contact your admin!')

    end

    describe 'call logging' do
      let(:token) { Setting.get('sipgate_token') }

      def sipgate_event(direction, params)
        post "/api/v1/sipgate/#{token}/#{direction}", params: params
        expect(response).to have_http_status(:ok)

        Cti::Log.find_by(call_id: Rack::Utils.parse_query(params)['callId'])
      end

      it 'maps an outbound call through all of its events', :aggregate_failures do
        expect(sipgate_event('out', 'event=newCall&direction=out&from=4930600000000&to=4912347114711&callId=1234567890-2&user%5B%5D=user+1')).to have_attributes(
          direction: 'out', from: '4930777000000', from_comment: 'user 1',
          to: '4912347114711', to_comment: 'CallerId Customer1', state: 'newCall'
        )
        expect(sipgate_event('out', 'event=answer&direction=out&callId=1234567890-2&from=4930600000000&to=4912347114711')).to have_attributes(state: 'answer')
        expect(sipgate_event('out', 'event=hangup&direction=out&callId=1234567890-2&cause=normalClearing&from=4930600000000&to=4912347114711')).to have_attributes(state: 'hangup', comment: 'normalClearing')
      end

      it 'maps an inbound call through all of its events', :aggregate_failures do
        expect(sipgate_event('in', 'event=newCall&direction=in&to=4930600000000&from=4912347114711&callId=1234567890-3&user%5B%5D=user+1')).to have_attributes(
          direction: 'in', from: '4912347114711', from_comment: 'CallerId Customer1',
          to: '4930600000000', to_comment: 'user 1', state: 'newCall', done: false
        )
        expect(sipgate_event('in', 'event=answer&direction=in&callId=1234567890-3&to=4930600000000&from=4912347114711')).to have_attributes(state: 'answer')
        expect(sipgate_event('in', 'event=hangup&direction=in&callId=1234567890-3&cause=normalClearing&to=4930600000000&from=4912347114711')).to have_attributes(state: 'hangup', comment: 'normalClearing')
      end

      it 'names the user given on answer, e.g. the voicemail', :aggregate_failures do
        expect(sipgate_event('in', 'event=newCall&direction=in&to=4930600000000&from=4912347114711&callId=1234567890-4&user%5B%5D=user+1,user+2')).to have_attributes(to_comment: 'user 1,user 2')
        expect(sipgate_event('in', 'event=answer&direction=in&callId=1234567890-4&to=4930600000000&from=4912347114711&user=voicemail')).to have_attributes(to_comment: 'voicemail')
      end

      it 'names every customer sharing the caller number' do
        expect(sipgate_event('in', 'event=newCall&direction=in&to=4930600000000&from=49999992222222&callId=1234567890-6&user%5B%5D=user+1,user+2'))
          .to have_attributes(from_comment: 'CallerId Customer3,CallerId Customer2')
      end

      it 'lists the logged calls to agents only', :aggregate_failures do
        sipgate_event('in', 'event=newCall&direction=in&to=4930600000000&from=4912347114711&callId=1234567890-1&user%5B%5D=user+1')
        travel 1.second
        sipgate_event('in', 'event=newCall&direction=in&to=4930600000000&from=49999992222222&callId=1234567890-2&user%5B%5D=user+1')

        get '/api/v1/cti/log'
        expect(response).to have_http_status(:forbidden)

        authenticated_as(agent)
        get '/api/v1/cti/log', as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response['list'].pluck('call_id')).to eq(%w[1234567890-2 1234567890-1])
      end
    end

    it 'alternative fqdn' do
      token = Setting.get('sipgate_token')

      Setting.set('sipgate_alternative_fqdn', 'external.host.example.com')

      # inbound - I
      params = 'event=newCall&direction=in&from=4912347114711&to=4930600000000&callId=4991155921769858278-1&user%5B%5D=user+1&user%5B%5D=user+2'
      post "/api/v1/sipgate/#{token}/in", params: params
      expect(response).to have_http_status(:ok)
      on_hangup = nil
      on_answer = nil
      content = response.body
      response_xml = REXML::Document.new(content)
      response_xml.elements.each('Response') do |element|
        on_hangup = element.attributes['onHangup']
        on_answer = element.attributes['onAnswer']
      end
      expect(on_hangup).to eq("http://external.host.example.com/api/v1/sipgate/#{token}/in")
      expect(on_answer).to eq("http://external.host.example.com/api/v1/sipgate/#{token}/in")
    end
  end
end
