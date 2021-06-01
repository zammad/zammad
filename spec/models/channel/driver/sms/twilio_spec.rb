# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Driver::Sms::Twilio do
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

    expect { api.send(channel.options, { recipient: 'asd', message: message_body }) }.to raise_exception(Twilio::REST::RestError)
    expect(a_request(:post, url_to_mock)).to have_been_made
  end

  private

  def create_channel
    FactoryBot.create(:channel,
                      options:       {
                        account_id: account_id,
                        adapter:    'sms/twilio',
                        sender:     sender_number,
                        token:      token
                      },
                      created_by_id: 1,
                      updated_by_id: 1)
  end

  # api parameters

  def url_to_mock
    "https://api.twilio.com/2010-04-01/Accounts/#{account_id}/Messages.json"
  end

  def account_id
    'ASDASDAS3213424AD'
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
    '{"sid": "SM07eab0404df148a4bf3712cb8b72e4c2", "date_created": "Fri, 01 Jun 2018 06:11:19 +0000", "date_updated": "Fri, 01 Jun 2018 06:11:19 +0000", "date_sent": null, "account_sid": "AC5989ff24c08f701b8b1ef09e1b79cbf8", "to": "+37060010000", "from": "+15005550006", "messaging_service_sid": null, "body": "Sent from your Twilio trial account - Test", "status": "queued", "num_segments": "1", "num_media": "0", "direction": "outbound-api", "api_version": "2010-04-01", "price": null, "price_unit": "USD", "error_code": null, "error_message": null, "uri": "/2010-04-01/Accounts/AC5989ff24c08f701b8b1ef09e1b79cbf8/Messages/SM07eab0404df148a4bf3712cb8b72e4c2.json", "subresource_uris": {"media": "/2010-04-01/Accounts/AC5989ff24c08f701b8b1ef09e1b79cbf8/Messages/SM07eab0404df148a4bf3712cb8b72e4c2/Media.json"}}'
  end

  def mocked_response_failure
    '{"code": 21211, "message": "The \'To\' number asd is not a valid phone number.", "more_info": "https://www.twilio.com/docs/errors/21211", "status": 400}'
  end
end
