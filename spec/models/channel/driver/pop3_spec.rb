# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Driver::Pop3 do
  before do
    stub_const('MockedMessage', Struct.new(:pop, :delete))

    allow_any_instance_of(Net::POP3)
      .to receive(:start)

    allow_any_instance_of(Net::POP3)
      .to receive(:finish)

    allow_any_instance_of(Net::POP3)
      .to receive(:enable_ssl)

    allow_any_instance_of(Net::POP3)
      .to receive(:mails)
      .and_return(message_ids)
  end

  describe '#check_configuration' do
    context 'when no messages exist' do
      let(:message_ids) { [] }

      it 'finds no content messages' do
        response = described_class
          .new
          .check_configuration({})

        expect(response).to include(
          result:           'ok',
          content_messages: be_zero,
        )
      end
    end

    context 'when a verify message exist' do
      let(:message_ids) do
        [
          MockedMessage.new(mock_a_message(verify: true)),
        ]
      end

      it 'finds no content messages' do
        response = described_class
          .new
          .check_configuration({})

        expect(response).to include(
          result:           'ok',
          content_messages: be_zero,
        )
      end
    end

    context 'when some content messages exist' do
      let(:message_ids) do
        [
          MockedMessage.new(mock_a_message),
          MockedMessage.new(mock_a_message),
          MockedMessage.new(mock_a_message),
        ]
      end

      it 'finds content messages' do
        response = described_class
          .new
          .check_configuration({})

        expect(response).to include(
          result:           'ok',
          content_messages: 3,
        )
      end
    end

    context 'when a verify and a content message exists' do
      let(:message_ids) do
        [
          MockedMessage.new(mock_a_message(verify: true)),
          MockedMessage.new(mock_a_message),
        ]
      end

      it 'finds content messages' do
        response = described_class
          .new
          .check_configuration({})

        expect(response).to include(
          result:           'ok',
          content_messages: 2,
        )
      end
    end
  end

  describe '#verify_transport' do
    let(:verify_message) { Faker::Lorem.unique.sentence }

    context 'when no messages exist' do
      let(:message_ids) { [] }

      it 'returns falsy response' do
        response = described_class
          .new
          .verify_transport({}, verify_message)

        expect(response).to include(result: 'verify not ok')
      end
    end

    context 'when a content message exists' do
      let(:message_ids) { [MockedMessage.new(mock_a_message)] }

      it 'returns falsy response' do
        response = described_class
          .new
          .verify_transport({}, verify_message)

        expect(response).to include(result: 'verify not ok')
      end
    end

    context 'when a verify message exists' do
      let(:message_ids) { [MockedMessage.new(mock_a_message(verify: verify_message))] }

      it 'returns truthy response with the correct verify string' do
        response = described_class
          .new
          .verify_transport({}, verify_message)

        expect(response).to include(result: 'ok')
      end

      it 'deletes the correct verify message' do
        allow(message_ids.first).to receive(:delete)

        described_class
          .new
          .verify_transport({}, verify_message)

        expect(message_ids.first).to have_received(:delete)
      end

      it 'returns falsy response with the wrong verify string' do
        response = described_class
          .new
          .verify_transport({}, 'another message')

        expect(response).to include(result: 'verify not ok')
      end

      it 'does not delete not matching verify message' do
        allow(message_ids.first).to receive(:delete)

        described_class
          .new
          .verify_transport({}, 'another message')

        expect(message_ids.first).not_to have_received(:delete)
      end
    end

    context 'when a content and a verify message exists' do
      let(:message_ids) { [MockedMessage.new(mock_a_message(verify: verify_message)), MockedMessage.new(mock_a_message)] }

      it 'returns truthy response' do
        response = described_class
          .new
          .verify_transport({}, verify_message)

        expect(response).to include(result: 'ok')
      end
    end
  end

  describe '#fetch', :aggregate_failures do
    let(:channel)     { create(:email_channel, :pop3) }
    let(:message)     { mock_a_message(subject: title) }
    let(:title)       { Faker::Lorem.unique.sentence }
    let(:message_ids) { [MockedMessage.new(message)] }

    context 'when fetching a regular email' do
      it 'handles messages correctly' do
        expect { channel.fetch }.to change(Ticket, :count)
        expect(Ticket).to exist(title:)
        expect(channel.reload.status_in).to eq('ok')
      end
    end

    context 'when fetching a verify message' do
      let(:message) { mock_a_message(verify: true) }

      it 'skips verify message without errors' do
        expect { channel.fetch }.not_to change(Ticket, :count)
        expect(channel.reload.status_in).to eq('ok')
      end
    end

    context 'when fetching oversized emails' do
      before do
        Setting.set('postmaster_max_size', 0.00001)
      end

      context 'with email reply' do
        it 'creates email reply correctly' do
          expect_any_instance_of(described_class).to receive(:process_oversized_mail)

          channel.fetch
        end
      end

      context 'without email reply' do
        before do
          Setting.set('postmaster_send_reject_if_mail_too_large', false)
        end

        it 'does not create email reply' do
          expect_any_instance_of(described_class).not_to receive(:process_oversized_mail)

          channel.fetch

          expect(channel.reload).to have_attributes(
            status_in:   'error',
            last_log_in: include('because message is too large')
          )
        end
      end
    end
  end

  def mock_a_message(subject: nil, verify: false)
    attrs = {
      from:         Faker::Internet.unique.email,
      to:           Faker::Internet.unique.email,
      body:         Faker::Lorem.sentence,
      subject:      verify.presence || subject.presence || Faker::Lorem.word,
      content_type: 'text/html',
    }

    if verify.present?
      attrs[:'X-Zammad-Ignore'] = 'true'
      attrs[:'X-Zammad-Verify'] = 'true'
      attrs[:'X-Zammad-Verify-Time'] = Time.current.iso8601
    end

    Channel::EmailBuild.build(**attrs).to_s
  end
end
