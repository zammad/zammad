require 'rails_helper'

RSpec.describe Channel::Driver::Sms::Massenversand do
  it 'passes' do
    channel = create_channel

    stub_request(:get, url_to_mock)
      .to_return(body: 'OK')

    api = channel.driver_instance.new
    expect(api.send(channel.options, { recipient: receiver_number, message: message_body })).to be true
  end

  it 'fails' do
    channel = create_channel

    stub_request(:get, url_to_mock)
      .to_return(body: 'blocked receiver ()')

    api = channel.driver_instance.new
    expect { api.send(channel.options, { recipient: receiver_number, message: message_body }) }.to raise_exception(RuntimeError)
  end

  private

  def create_channel
    FactoryBot.create(:channel,
                      options:       {
                        adapter: 'sms/massenversand',
                        gateway: gateway,
                        sender:  sender_number,
                        token:   token
                      },
                      created_by_id: 1,
                      updated_by_id: 1)
  end

  def url_to_mock
    params = {
      authToken: token,
      getID:     1,
      msg:       message_body,
      msgtype:   'c',
      receiver:  receiver_number,
      sender:    sender_number
    }

    gateway + '?' + URI.encode_www_form(params)
  end

  # api parameters

  def gateway
    'https://gate1.goyyamobile.com/sms/sendsms.asp'
  end

  def message_body
    'Test'
  end

  def receiver_number
    '+37060010000'
  end

  def sender_number
    '+491000000000'
  end

  def token
    '00q1234123423r5rwefdfsfsfef'
  end
end
