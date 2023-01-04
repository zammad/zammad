# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'messagebird'

RSpec.describe Channel::Driver::Sms::MessageBird do
  it 'passes' do
    channel = create_channel

    stub_request(:post, url_to_mock)
      .to_return(body: mocked_response_success)

    api = channel.driver_instance.new
    expect(api.send(channel.options, { recipient: '+37060010000', message: message_body })).to be true
  end

  it 'fails' do
    channel = create_channel

    stub_request(:post, url_to_mock)
      .to_return(status: 400, body: mocked_response_failure)

    api = channel.driver_instance.new

    expect { api.send(channel.options, { recipient: 'asd', message: message_body }) }.to raise_exception(MessageBird::ServerException)
  end

  private

  def create_channel
    create(:channel,
           options:       {
             adapter: 'sms/message_bird',
             sender:  sender_number,
             token:   token
           },
           created_by_id: 1,
           updated_by_id: 1)
  end

  # api parameters

  def url_to_mock
    'https://rest.messagebird.com/messages'
  end

  def message_body
    'Test'
  end

  def sender_number
    '+15005550006'
  end

  def token
    '2345r4erfdvc4wedxv3efds'
  end

  # mocked responses

  def mocked_response_success
    '{"id":"1e8cc35873d14fe4ab18bd97a412121","href":"https://rest.messagebird.com/messages/1e8cc35873d14fe4ab18bd121212f971a","direction":"mt","type":"sms","originator":"Zammad GmbH","body":"This is a test messageNEW","reference":"Foobar","validity":null,"gateway":10,"typeDetails":{},"datacoding":"plain","mclass":1,"scheduledDatetime":null,"createdDatetime":"2021-07-22T13:25:03+00:00","recipients":{"totalCount":1,"totalSentCount":1,"totalDeliveredCount":0,"totalDeliveryFailedCount":0,"items":[{"recipient":491234,"status":"sent","statusDatetime":"2021-07-22T13:25:03+00:00","messagePartCount":1}]}}'
  end

  def mocked_response_failure
    '{"errors":[{"code":9,"description":"no (correct) recipients found","parameter":"recipient"}]}'
  end
end
