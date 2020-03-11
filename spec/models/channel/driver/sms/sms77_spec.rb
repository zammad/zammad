require 'rails_helper'

RSpec.describe Channel::Driver::Sms::Sms77 do
  it 'passes' do
    channel = create_channel

    stub_request(:get, url_to_mock)
        .to_return(body: '100')

    api = channel.driver_instance.new
    expect(api.send(channel.options, {to: to, text: text})).to be true
  end

  it 'fails' do
    channel = create_channel

    stub_request(:get, url_to_mock)
        .to_return(body: '900')

    api = channel.driver_instance.new
    expect { api.send(channel.options, {to: to, text: text}) }.to raise_exception(RuntimeError)
  end

  private

  def create_channel
    FactoryBot.create(:channel,
                      options: {
                          adapter: 'sms/sms77',
                          from: from,
                          api_key: api_key
                      },
                      created_by_id: 1,
                      updated_by_id: 1)
  end

  def url_to_mock
    params = {
        p: api_key,
        text: text,
        to: to,
        from: from
    }

    'https://gateway.sms77.io/api/sms?' + URI.encode_www_form(params)
  end

  # api parameters

  def text
    'Test'
  end

  def to
    '+491771783130'
  end

  def from
    '+491000000000'
  end

  def api_key
    'HeJyJSAvBWDn5RwNfhQGKZI6poCLk7pUXjpxctipYHWGsjoHtWNDI3d4De8gkoVe'
  end
end
