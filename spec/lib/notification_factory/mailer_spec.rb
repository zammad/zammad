# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'ostruct'

RSpec.describe NotificationFactory::Mailer do
  describe '#template' do
    context 'for postmaster oversized mail' do
      let(:raw_incoming_mail) { Rails.root.join('test/data/mail/mail010.box').read }

      let(:parsed_incoming_mail) { Channel::EmailParser.new.parse raw_incoming_mail }

      let(:incoming_mail) do
        mail = Channel::EmailParser::MESSAGE_STRUCT.new
        mail.from_display_name = parsed_incoming_mail[:from_display_name]
        mail.subject = parsed_incoming_mail[:subject]
        mail.msg_size = format('%<MB>.2f', MB: raw_incoming_mail.size.to_f / 1024 / 1024)
        mail
      end

      let(:en_expected_subject) { '[undeliverable] Message too large' }

      let(:en_expected_body) do
        <<~BODY
          Dear Smith Sepp,

          Unfortunately your email titled \"Gruß aus Oberalteich\" could not be delivered to one or more recipients.

          Your message was 0.01 MB but we only accept messages up to 10 MB.

          Please reduce the message size and try again. Thank you for your understanding.

          Regretfully,

          Postmaster of zammad.example.com
        BODY
      end

      shared_examples 'plaintext mail templating' do
        it 'templates correctly' do
          result = described_class.template(
            template:   'email_oversized',
            locale:     locale,
            format:     'txt',
            objects:    {
              mail: incoming_mail,
            },
            raw:        true, # will not add application template
            standalone: true, # default: false - will send header & footer
          )
          expect(result[:subject]).to eq(expected_subject)
          expect(result[:body]).to eq(expected_body)
        end
      end

      context 'English locale (en)' do
        include_examples 'plaintext mail templating' do
          let(:locale) { 'en' }
          let(:expected_subject) { en_expected_subject }
          let(:expected_body)    { en_expected_body }
        end
      end

      context 'German locale (de)' do
        include_examples 'plaintext mail templating' do
          let(:locale) { 'de' }
          let(:expected_subject) { '[Unzustellbar] Nachricht zu groß' }
          let(:expected_body) do
            <<~BODY
              Hallo Smith Sepp,

              Ihre E-Mail mit dem Betreff \"Gruß aus Oberalteich\" konnte nicht an einen oder mehrere Empfänger zugestellt werden.

              Die Nachricht hatte eine Größe von 0.01 MB, wir akzeptieren jedoch nur E-Mails mit einer Größe von bis zu 10 MB.

              Bitte reduzieren Sie die Größe Ihrer Nachricht und versuchen Sie es erneut. Vielen Dank für Ihr Verständnis.

              Mit freundlichen Grüßen

              Postmaster von zammad.example.com
            BODY
          end
        end
      end

      context 'unsupported locale, which defaults back to English locale (en)' do
        include_examples 'plaintext mail templating' do
          let(:locale) { 'UNSUPPORTED_LOCALE' }
          let(:expected_subject) { en_expected_subject }
          let(:expected_body)    { en_expected_body }
        end
      end
    end
  end

  describe '#send' do
    subject(:result) do
      described_class.send(
        recipient: user,
        subject:   'some subject',
        body:      'some body',
      )
    end

    context 'recipient with email address' do
      let(:user) { create(:agent, email: 'somebody@example.com') }

      it 'returns a Mail::Message' do
        expect(result).to be_a(Mail::Message)
      end
    end

    context 'recipient without email address' do
      let(:user) { create(:agent, email: '') }

      it 'raises Exceptions::UnprocessableEntity' do
        expect { result }.to raise_error(Exceptions::UnprocessableEntity)
      end
    end
  end

end
