# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Driver::Sms::Massenversand do
  let(:gateway) { 'https://gate1.goyyamobile.com/sms/sendsms.asp' }
  let(:message_body) { 'Test' }
  let(:receiver_number) { '+37060010000' }
  let(:sender_number) { '+491000000000' }
  let(:token) { '00q1234123423r5rwefdfsfsfef' }
  let(:url) { "#{gateway}?#{params}" }
  let(:params) do
    URI.encode_www_form(
      authToken: token,
      getID:     1,
      msg:       message_body,
      msgtype:   'c',
      receiver:  receiver_number,
      sender:    sender_number
    )
  end
  let(:channel) do
    create(:channel,
           options:       {
             adapter: 'sms/massenversand',
             gateway: gateway,
             sender:  sender_number,
             token:   token
           },
           created_by_id: 1,
           updated_by_id: 1)
  end
  let(:instance) { described_class.new }

  context 'when gateway returns OK' do

    before do
      stub_request(:get, url).to_return(body: 'OK')
    end

    it 'passes' do
      expect(instance.send(channel.options, { recipient: receiver_number, message: message_body })).to be true
    end
  end

  context 'when gateway response is invalid' do

    before do
      stub_request(:get, url).to_return(body: body)
    end

    context 'when receiver is blocked' do
      let(:body) { 'blocked receiver ()' }

      it 'raises RuntimeError' do # rubocop:disable RSpec/MultipleExpectations
        expect { instance.send(channel.options, { recipient: receiver_number, message: message_body }) }.to raise_error { |error|
          expect(error.message).not_to include(body)
        }
      end
    end
  end
end
