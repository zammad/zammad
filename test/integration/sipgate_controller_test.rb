# encoding: utf-8
require 'test_helper'
require 'rexml/document'

class SipgateControllerTest < ActionDispatch::IntegrationTest
  setup do

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

  end

  test 'basic call' do

    # inbound - I
    params = 'event=newCall&direction=in&from=4912347114711&to=4930600000000&callId=4991155921769858278&user%5B%5D=user+1&user%5B%5D=user+2'
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
    params = 'event=newCall&direction=in&from=491715000000&to=4930600000000&callId=4991155921769858278&user%5B%5D=user+1&user%5B%5D=user+2'
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
    params = 'event=newCall&direction=out&from=4930600000000&to=4912347114711&callId=8621106404543334274&user%5B%5D=user+1'
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
    assert_equal('http://zammad.example.com/api/v1/sipgate/in', on_hangup)
    assert_equal('http://zammad.example.com/api/v1/sipgate/in', on_answer)

    # outbound - II - set caller_id based on routing_table by explicite number
    params = 'event=newCall&direction=out&from=4930600000000&to=491714000000&callId=8621106404543334274&user%5B%5D=user+1'
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
    assert_equal('http://zammad.example.com/api/v1/sipgate/in', on_hangup)
    assert_equal('http://zammad.example.com/api/v1/sipgate/in', on_answer)

    # outbound - III - set caller_id based on routing_table by 41*
    params = 'event=newCall&direction=out&from=4930600000000&to=4147110000000&callId=8621106404543334274&user%5B%5D=user+1'
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
    assert_equal('http://zammad.example.com/api/v1/sipgate/in', on_hangup)
    assert_equal('http://zammad.example.com/api/v1/sipgate/in', on_answer)

  end

end
