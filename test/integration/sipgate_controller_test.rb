# encoding: utf-8
require 'test_helper'
require 'rexml/document'

class SipgateControllerTest < ActionDispatch::IntegrationTest
  setup do

    Cti::Log.destroy_all

    Setting.create_or_update(
      title: 'sipgate.io integration',
      name: 'sipgate_integration',
      area: 'Integration::Switch',
      description: 'Define if sipgate.io (http://www.sipgate.io) is enabled or not.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'sipgate_integration',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state: true,
      preferences: { prio: 1 },
      frontend: false
    )
    Setting.create_or_update(
      title: 'sipgate.io config',
      name: 'sipgate_config',
      area: 'Integration::Sipgate',
      description: 'Define the sipgate.io config.',
      options: {},
      state: {
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
      },
      frontend: false,
      preferences: { prio: 2 },
    )

    groups = Group.where(name: 'Users')
    roles  = Role.where(name: 'Agent')
    agent  = User.create_or_update(
      login: 'cti-agent@example.com',
      firstname: 'E',
      lastname: 'S',
      email: 'cti-agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1,
    )

  end

  test 'basic call' do

    # inbound - I
    params = 'event=newCall&direction=in&from=4912347114711&to=4930600000000&callId=4991155921769858278-1&user%5B%5D=user+1&user%5B%5D=user+2'
    post '/api/v1/sipgate/in', params
    assert_response(200)
    on_hangup = nil
    on_answer = nil
    content = @response.body
    response = REXML::Document.new(content)
    response.elements.each('Response') do |element|
      on_hangup = element.attributes['onHangup']
      on_answer = element.attributes['onAnswer']
    end
    assert_equal('http://zammad.example.com/api/v1/sipgate/in', on_hangup)
    assert_equal('http://zammad.example.com/api/v1/sipgate/in', on_answer)

    # inbound - II - block caller
    params = 'event=newCall&direction=in&from=491715000000&to=4930600000000&callId=4991155921769858278-2&user%5B%5D=user+1&user%5B%5D=user+2'
    post '/api/v1/sipgate/in', params
    assert_response(200)
    on_hangup = nil
    on_answer = nil
    content = @response.body
    response = REXML::Document.new(content)
    response.elements.each('Response') do |element|
      on_hangup = element.attributes['onHangup']
      on_answer = element.attributes['onAnswer']
    end
    assert_equal('http://zammad.example.com/api/v1/sipgate/in', on_hangup)
    assert_equal('http://zammad.example.com/api/v1/sipgate/in', on_answer)
    reason = nil
    response.elements.each('Response/Reject') do |element|
      reason = element.attributes['reason']
    end
    assert_equal('busy', reason)

    # outbound - I - set default_caller_id
    params = 'event=newCall&direction=out&from=4930600000000&to=4912347114711&callId=8621106404543334274-3&user%5B%5D=user+1'
    post '/api/v1/sipgate/out', params
    assert_response(200)
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
    assert_equal('4930777000000', caller_id)
    assert_equal('4912347114711', number_to_dail)
    assert_equal('http://zammad.example.com/api/v1/sipgate/out', on_hangup)
    assert_equal('http://zammad.example.com/api/v1/sipgate/out', on_answer)

    # outbound - II - set caller_id based on routing_table by explicite number
    params = 'event=newCall&direction=out&from=4930600000000&to=491714000000&callId=8621106404543334274-4&user%5B%5D=user+1'
    post '/api/v1/sipgate/out', params
    assert_response(200)
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
    assert_equal('41715880339000', caller_id)
    assert_equal('491714000000', number_to_dail)
    assert_equal('http://zammad.example.com/api/v1/sipgate/out', on_hangup)
    assert_equal('http://zammad.example.com/api/v1/sipgate/out', on_answer)

    # outbound - III - set caller_id based on routing_table by 41*
    params = 'event=newCall&direction=out&from=4930600000000&to=4147110000000&callId=8621106404543334274-5&user%5B%5D=user+1'
    post '/api/v1/sipgate/out', params
    assert_response(200)
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
    assert_equal('41715880339000', caller_id)
    assert_equal('4147110000000', number_to_dail)
    assert_equal('http://zammad.example.com/api/v1/sipgate/out', on_hangup)
    assert_equal('http://zammad.example.com/api/v1/sipgate/out', on_answer)

    # no config
    Setting.set('sipgate_config', {})
    params = 'event=newCall&direction=in&from=4912347114711&to=4930600000000&callId=4991155921769858278-6&user%5B%5D=user+1&user%5B%5D=user+2'
    post '/api/v1/sipgate/in', params
    assert_response(422)
    error = nil
    content = @response.body
    response = REXML::Document.new(content)
    response.elements.each('Response/Error') do |element|
      error = element.text
    end
    assert_equal('Feature not configured, please contact your admin!', error)

  end

  test 'log call' do

    # outbound - I - new call
    params = 'event=newCall&direction=out&from=4930600000000&to=4912347114711&callId=1234567890-1&user%5B%5D=user+1'
    post '/api/v1/sipgate/out', params
    assert_response(200)
    log = Cti::Log.find_by(call_id: '1234567890-1')
    assert(log)
    assert_equal('4930777000000', log.from)
    assert_equal('4912347114711', log.to)
    assert_equal('out', log.direction)
    assert_equal('user 1', log.from_comment)
    assert_equal(nil, log.comment)
    assert_equal('newCall', log.state)

    # outbound - I - hangup by agent
    params = 'event=hangup&direction=out&callId=1234567890-1&cause=cancel'
    post '/api/v1/sipgate/out', params
    assert_response(200)
    log = Cti::Log.find_by(call_id: '1234567890-1')
    assert(log)
    assert_equal('4930777000000', log.from)
    assert_equal('4912347114711', log.to)
    assert_equal('out', log.direction)
    assert_equal('user 1', log.from_comment)
    assert_equal('cancel', log.comment)
    assert_equal('hangup', log.state)

    # outbound - II - new call
    params = 'event=newCall&direction=out&from=4930600000000&to=4912347114711&callId=1234567890-2&user%5B%5D=user+1'
    post '/api/v1/sipgate/out', params
    assert_response(200)
    log = Cti::Log.find_by(call_id: '1234567890-2')
    assert(log)
    assert_equal('4930777000000', log.from)
    assert_equal('4912347114711', log.to)
    assert_equal('out', log.direction)
    assert_equal('user 1', log.from_comment)
    assert_equal(nil, log.comment)
    assert_equal('newCall', log.state)

    # outbound - II - answer by customer
    params = 'event=answer&direction=out&callId=1234567890-2&from=4930600000000&to=4912347114711'
    post '/api/v1/sipgate/out', params
    assert_response(200)
    log = Cti::Log.find_by(call_id: '1234567890-2')
    assert(log)
    assert_equal('4930777000000', log.from)
    assert_equal('4912347114711', log.to)
    assert_equal('out', log.direction)
    assert_equal('user 1', log.from_comment)
    assert_equal(nil, log.comment)
    assert_equal('answer', log.state)

    # outbound - II - hangup by customer
    params = 'event=hangup&direction=out&callId=1234567890-2&cause=normalClearing&from=4930600000000&to=4912347114711'
    post '/api/v1/sipgate/out', params
    assert_response(200)
    log = Cti::Log.find_by(call_id: '1234567890-2')
    assert(log)
    assert_equal('4930777000000', log.from)
    assert_equal('4912347114711', log.to)
    assert_equal('out', log.direction)
    assert_equal('user 1', log.from_comment)
    assert_equal('normalClearing', log.comment)
    assert_equal('hangup', log.state)

    # inbound - I - new call
    params = 'event=newCall&direction=in&to=4930600000000&from=4912347114711&callId=1234567890-3&user%5B%5D=user+1'
    post '/api/v1/sipgate/in', params
    assert_response(200)
    log = Cti::Log.find_by(call_id: '1234567890-3')
    assert(log)
    assert_equal('4930600000000', log.to)
    assert_equal('4912347114711', log.from)
    assert_equal('in', log.direction)
    assert_equal('user 1', log.to_comment)
    assert_equal(nil, log.comment)
    assert_equal('newCall', log.state)

    # inbound - I - answer by customer
    params = 'event=answer&direction=in&callId=1234567890-3&to=4930600000000&from=4912347114711'
    post '/api/v1/sipgate/in', params
    assert_response(200)
    log = Cti::Log.find_by(call_id: '1234567890-3')
    assert(log)
    assert_equal('4930600000000', log.to)
    assert_equal('4912347114711', log.from)
    assert_equal('in', log.direction)
    assert_equal('user 1', log.to_comment)
    assert_equal(nil, log.comment)
    assert_equal('answer', log.state)

    # inbound - I - hangup by customer
    params = 'event=hangup&direction=in&callId=1234567890-3&cause=normalClearing&to=4930600000000&from=4912347114711'
    post '/api/v1/sipgate/in', params
    assert_response(200)
    log = Cti::Log.find_by(call_id: '1234567890-3')
    assert(log)
    assert_equal('4930600000000', log.to)
    assert_equal('4912347114711', log.from)
    assert_equal('in', log.direction)
    assert_equal('user 1', log.to_comment)
    assert_equal('normalClearing', log.comment)
    assert_equal('hangup', log.state)

    get '/api/v1/cti/log'
    assert_response(401)

    headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('cti-agent@example.com', 'agentpw')
    get '/api/v1/cti/log', {}, headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Array)
    assert_equal(3, result.count)

  end

end
