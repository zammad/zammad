# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Driver::Sendmail do
  context 'with env var ZAMMAD_MAIL_TO_FILE present' do

    let(:address) { Faker::Internet.email }
    let(:body)    { Faker::Lorem.sentence(word_count: 3) }
    let(:file)    { Rails.root.join("tmp/mails/#{address}.eml") }

    around do |example|
      ENV['ZAMMAD_MAIL_TO_FILE'] = '1'
      FileUtils.rm_f(file)
      example.run
      FileUtils.rm_f(file)
      ENV.delete('ZAMMAD_MAIL_TO_FILE')
    end

    it 'creates mail file', :aggregate_failures do
      described_class.new.deliver({}, { to: address, from: address, body: body })
      expect(file).to exist
      content = File.read(file)
      expect(content).to match(%r{#{body}})
      expect(content).to match(%r{#{address}})
    end
  end

  context 'with regular Sendmail usage' do
    let(:address) { Faker::Internet.email }
    let(:body)    { Faker::Lorem.sentence(word_count: 3) }

    let(:mocked_sendmail) do
      instance_double(IO).tap do |dbl|
        allow(dbl).to receive(:puts)
        allow(dbl).to receive(:flush)
      end
    end

    around do |example|
      ENV['ZAMMAD_MAIL_PRETEND_NOT_TEST'] = '1'
      example.run
      ENV.delete('ZAMMAD_MAIL_PRETEND_NOT_TEST')
    end

    it 'sends mail', :aggregate_failures do
      allow_any_instance_of(Mail::Sendmail).to receive(:popen).and_yield(mocked_sendmail)

      described_class.new.deliver({}, { to: address, from: address, body: body })

      expect(mocked_sendmail).to have_received(:puts).with(include(address).and(include(body)))
      expect(mocked_sendmail).to have_received(:flush)
    end
  end

  describe '#deliver' do
    let(:channel) { create(:email_notification_channel, :sendmail) }

    context 'when an error is raised', aggregate_failures: true do
      before do
        allow_any_instance_of(Mail::Message).to receive(:deliver).and_raise(error)
      end

      let(:error) { StandardError.new('custom error message') }

      it 'forwards the error' do
        expect { channel.deliver({}) }
          .to raise_error(Channel::DeliveryError) { |error|
            expect(error.original_error.message).to eq('sendmail: custom error message')
          }
      end

      context 'when it was sending a notification' do
        it 'forwards the error' do
          expect { channel.deliver({}, true) }
            .to raise_error(Channel::DeliveryError) { |error|
              expect(error.original_error.message).to eq('sendmail: custom error message')
            }
        end
      end
    end
  end
end
