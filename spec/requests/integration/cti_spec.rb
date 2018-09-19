require 'rails_helper'

RSpec.describe 'Integration CTI', type: :request do

  let(:agent_user) do
    create(:agent_user)
  end
  let!(:customer_user1) do
    create(
      :customer_user,
      login: 'ticket-caller_id_cti-customer1@example.com',
      firstname: 'CallerId',
      lastname: 'Customer1',
      phone: '+49 99999 222222',
      fax: '+49 99999 222223',
      mobile: '+4912347114711',
      note: 'Phone at home: +49 99999 222224',
    )
  end
  let!(:customer_user2) do
    create(
      :customer_user,
      login: 'ticket-caller_id_cti-customer2@example.com',
      firstname: 'CallerId',
      lastname: 'Customer2',
      phone: '+49 99999 222222 2',
    )
  end
  let!(:customer_user3) do
    create(
      :customer_user,
      login: 'ticket-caller_id_cti-customer3@example.com',
      firstname: 'CallerId',
      lastname: 'Customer3',
      phone: '+49 99999 222222 2',
    )
  end

  before(:each) do
    Cti::Log.destroy_all

    Setting.set('cti_integration', true)
    Setting.set('cti_config', {
                  outbound: {
                    routing_table: [
                      {
                        dest: '41*',
                        caller_id: '41715880339000',
                      },
                      {
                        dest: '491714000000',
                        caller_id: '41715880339000',
                      },
                    ],
                    default_caller_id: '4930777000000',
                  },
                  inbound: {
                    block_caller_ids: [
                      {
                        caller_id: '491715000000',
                        note: 'some note',
                      }
                    ],
                    notify_user_ids: {
                      2 => true,
                      4 => false,
                    },
                  }
                })

    Cti::CallerId.rebuild
  end

  describe 'request handling' do

    it 'does token check' do
      params = 'event=newCall&direction=in&from=4912347114711&to=4930600000000&call_id=4991155921769858278-1&user%5B%5D=user+1&user%5B%5D=user+2'
      post '/api/v1/cti/not_existing_token', params: params
      expect(response).to have_http_status(401)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Invalid token, please contact your admin!')
    end

    it 'does basic call' do
      token = Setting.get('cti_token')

      # inbound - I
      params = 'event=newCall&direction=in&from=4912347114711&to=4930600000000&call_id=4991155921769858278-1&user%5B%5D=user+1&user%5B%5D=user+2'
      post "/api/v1/cti/#{token}", params: params
      expect(response).to have_http_status(200)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_blank

      # inbound - II - block caller
      params = 'event=newCall&direction=in&from=491715000000&to=4930600000000&call_id=4991155921769858278-2&user%5B%5D=user+1&user%5B%5D=user+2'
      post "/api/v1/cti/#{token}", params: params
      expect(response).to have_http_status(200)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['action']).to eq('reject')
      expect(json_response['reason']).to eq('busy')

      # outbound - I - set default_caller_id
      params = 'event=newCall&direction=out&from=4930600000000&to=4912347114711&call_id=8621106404543334274-3&user%5B%5D=user+1'
      post "/api/v1/cti/#{token}", params: params
      expect(response).to have_http_status(200)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['action']).to eq('dial')
      expect(json_response['number']).to eq('4912347114711')
      expect(json_response['caller_id']).to eq('4930777000000')

      # outbound - II - set caller_id based on routing_table by explicite number
      params = 'event=newCall&direction=out&from=4930600000000&to=491714000000&call_id=8621106404543334274-4&user%5B%5D=user+1'
      post "/api/v1/cti/#{token}", params: params
      expect(response).to have_http_status(200)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['action']).to eq('dial')
      expect(json_response['number']).to eq('491714000000')
      expect(json_response['caller_id']).to eq('41715880339000')

      # outbound - III - set caller_id based on routing_table by 41*
      params = 'event=newCall&direction=out&from=4930600000000&to=4147110000000&call_id=8621106404543334274-5&user%5B%5D=user+1'
      post "/api/v1/cti/#{token}", params: params
      expect(response).to have_http_status(200)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['action']).to eq('dial')
      expect(json_response['number']).to eq('4147110000000')
      expect(json_response['caller_id']).to eq('41715880339000')

      # no config
      Setting.set('cti_config', {})
      params = 'event=newCall&direction=in&from=4912347114711&to=4930600000000&call_id=4991155921769858278-6&user%5B%5D=user+1&user%5B%5D=user+2'
      post "/api/v1/cti/#{token}", params: params
      expect(response).to have_http_status(422)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Feature not configured, please contact your admin!')

    end

    it 'does log call' do
      token = Setting.get('cti_token')

      # outbound - I - new call
      params = 'event=newCall&direction=out&from=4930600000000&to=4912347114711&call_id=1234567890-1&user%5B%5D=user+1'
      post "/api/v1/cti/#{token}", params: params
      expect(response).to have_http_status(200)
      log = Cti::Log.find_by(call_id: '1234567890-1')
      expect(log).to be_truthy
      expect(log.from).to eq('4930777000000')
      expect(log.to).to eq('4912347114711')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to eq('user 1')
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('newCall')
      expect(log.done).to eq(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      # outbound - I - hangup by agent
      params = 'event=hangup&direction=out&call_id=1234567890-1&cause=cancel'
      post "/api/v1/cti/#{token}", params: params
      expect(response).to have_http_status(200)
      log = Cti::Log.find_by(call_id: '1234567890-1')
      expect(log).to be_truthy
      expect(log.from).to eq('4930777000000')
      expect(log.to).to eq('4912347114711')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to eq('user 1')
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to eq('cancel')
      expect(log.state).to eq('hangup')
      expect(log.done).to eq(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_truthy
      expect(log.duration_waiting_time).to be_truthy
      expect(log.duration_talking_time).to be_nil

      # outbound - II - new call
      params = 'event=newCall&direction=out&from=4930600000000&to=4912347114711&call_id=1234567890-2&user%5B%5D=user+1'
      post "/api/v1/cti/#{token}", params: params
      expect(response).to have_http_status(200)
      log = Cti::Log.find_by(call_id: '1234567890-2')
      expect(log).to be_truthy
      expect(log.from).to eq('4930777000000')
      expect(log.to).to eq('4912347114711')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to eq('user 1')
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('newCall')
      expect(log.done).to eq(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      # outbound - II - answer by customer
      params = 'event=answer&direction=out&call_id=1234567890-2&from=4930600000000&to=4912347114711'
      post "/api/v1/cti/#{token}", params: params
      expect(response).to have_http_status(200)
      log = Cti::Log.find_by(call_id: '1234567890-2')
      expect(log).to be_truthy
      expect(log.from).to eq('4930777000000')
      expect(log.to).to eq('4912347114711')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to eq('user 1')
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('answer')
      expect(log.done).to eq(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_truthy
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_truthy
      expect(log.duration_talking_time).to be_nil

      # outbound - II - hangup by customer
      params = 'event=hangup&direction=out&call_id=1234567890-2&cause=normalClearing&from=4930600000000&to=4912347114711'
      post "/api/v1/cti/#{token}", params: params
      expect(response).to have_http_status(200)
      log = Cti::Log.find_by(call_id: '1234567890-2')
      expect(log).to be_truthy
      expect(log.from).to eq('4930777000000')
      expect(log.to).to eq('4912347114711')
      expect(log.direction).to eq('out')
      expect(log.from_comment).to eq('user 1')
      expect(log.to_comment).to eq('CallerId Customer1')
      expect(log.comment).to eq('normalClearing')
      expect(log.state).to eq('hangup')
      expect(log.done).to eq(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_truthy
      expect(log.end_at).to be_truthy
      expect(log.duration_waiting_time).to be_truthy
      expect(log.duration_talking_time).to be_truthy

      # inbound - I - new call
      params = 'event=newCall&direction=in&to=4930600000000&from=4912347114711&call_id=1234567890-3&user%5B%5D=user+1'
      post "/api/v1/cti/#{token}", params: params
      expect(response).to have_http_status(200)
      log = Cti::Log.find_by(call_id: '1234567890-3')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('user 1')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('newCall')
      expect(log.done).to eq(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      # inbound - I - answer by customer
      params = 'event=answer&direction=in&call_id=1234567890-3&to=4930600000000&from=4912347114711'
      post "/api/v1/cti/#{token}", params: params
      expect(response).to have_http_status(200)
      log = Cti::Log.find_by(call_id: '1234567890-3')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('user 1')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('answer')
      expect(log.done).to eq(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_truthy
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_truthy
      expect(log.duration_talking_time).to be_nil

      # inbound - I - hangup by customer
      params = 'event=hangup&direction=in&call_id=1234567890-3&cause=normalClearing&to=4930600000000&from=4912347114711'
      post "/api/v1/cti/#{token}", params: params
      expect(response).to have_http_status(200)
      log = Cti::Log.find_by(call_id: '1234567890-3')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('user 1')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to eq('normalClearing')
      expect(log.state).to eq('hangup')
      expect(log.done).to eq(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_truthy
      expect(log.end_at).to be_truthy
      expect(log.duration_waiting_time).to be_truthy
      expect(log.duration_talking_time).to be_truthy

      # inbound - II - new call
      params = 'event=newCall&direction=in&to=4930600000000&from=4912347114711&call_id=1234567890-4&user%5B%5D=user+1,user+2'
      post "/api/v1/cti/#{token}", params: params
      expect(response).to have_http_status(200)
      log = Cti::Log.find_by(call_id: '1234567890-4')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('user 1,user 2')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('newCall')
      expect(log.done).to eq(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      # inbound - II - answer by voicemail
      params = 'event=answer&direction=in&call_id=1234567890-4&to=4930600000000&from=4912347114711&user=voicemail'
      post "/api/v1/cti/#{token}", params: params
      expect(response).to have_http_status(200)
      log = Cti::Log.find_by(call_id: '1234567890-4')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('voicemail')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('answer')
      expect(log.done).to eq(true)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_truthy
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_truthy
      expect(log.duration_talking_time).to be_nil

      # inbound - II - hangup by customer
      params = 'event=hangup&direction=in&call_id=1234567890-4&cause=normalClearing&to=4930600000000&from=4912347114711'
      post "/api/v1/cti/#{token}", params: params
      expect(response).to have_http_status(200)
      log = Cti::Log.find_by(call_id: '1234567890-4')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('voicemail')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to eq('normalClearing')
      expect(log.state).to eq('hangup')
      expect(log.done).to eq(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_truthy
      expect(log.end_at).to be_truthy
      expect(log.duration_waiting_time).to be_truthy
      expect(log.duration_talking_time).to be_truthy

      # inbound - III - new call
      params = 'event=newCall&direction=in&to=4930600000000&from=4912347114711&call_id=1234567890-5&user%5B%5D=user+1,user+2'
      post "/api/v1/cti/#{token}", params: params
      expect(response).to have_http_status(200)
      log = Cti::Log.find_by(call_id: '1234567890-5')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('user 1,user 2')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to be_nil
      expect(log.state).to eq('newCall')
      expect(log.done).to eq(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      # inbound - III - hangup by customer
      params = 'event=hangup&direction=in&call_id=1234567890-5&cause=normalClearing&to=4930600000000&from=4912347114711'
      post "/api/v1/cti/#{token}", params: params
      expect(response).to have_http_status(200)
      log = Cti::Log.find_by(call_id: '1234567890-5')
      expect(log).to be_truthy
      expect(log.to).to eq('4930600000000')
      expect(log.from).to eq('4912347114711')
      expect(log.direction).to eq('in')
      expect(log.to_comment).to eq('user 1,user 2')
      expect(log.from_comment).to eq('CallerId Customer1')
      expect(log.comment).to eq('normalClearing')
      expect(log.state).to eq('hangup')
      expect(log.done).to eq(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_truthy
      expect(log.duration_waiting_time).to be_truthy
      expect(log.duration_talking_time).to be_nil

      # inbound - IV - new call
      params = 'event=newCall&direction=in&to=4930600000000&from=49999992222222&call_id=1234567890-6&user%5B%5D=user+1,user+2'
      post "/api/v1/cti/#{token}", params: params
      expect(response).to have_http_status(200)
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
      expect(log.done).to eq(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      # inbound - IV - new call
      params = 'event=newCall&direction=in&to=4930600000000&from=anonymous&call_id=1234567890-7&user%5B%5D=user+1,user+2'
      post "/api/v1/cti/#{token}", params: params
      expect(response).to have_http_status(200)
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
      expect(log.state).to eq('newCall')
      expect(log.done).to eq(false)
      expect(log.initialized_at).to be_truthy
      expect(log.start_at).to be_nil
      expect(log.end_at).to be_nil
      expect(log.duration_waiting_time).to be_nil
      expect(log.duration_talking_time).to be_nil

      # get caller list
      get '/api/v1/cti/log'
      expect(response).to have_http_status(401)

      authenticated_as(agent_user)
      get '/api/v1/cti/log', as: :json
      expect(response).to have_http_status(200)
      expect(json_response['list']).to be_a_kind_of(Array)
      expect(json_response['list'].count).to eq(7)
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['User']).to be_truthy
      expect(json_response['assets']['User'][customer_user2.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][customer_user3.id.to_s]).to be_truthy
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
  end
end
