# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'ostruct'

RSpec.describe NotificationFactory::Mailer do
  describe '#template' do

    context 'with application template' do
      let(:result) { described_class.template(template: 'test_ticket', locale: locale, objects: {}) }

      context 'with English locale' do
        let(:locale) { 'en' }

        it 'renders correctly' do
          expect(result[:subject]).to eq('Test Ticket!')
          expect(result[:body]).to include('Your Zammad Helpdesk Team')
          expect(result[:body]).to include('Manage your notification settings')
        end
      end

      context 'with German locale' do
        let(:locale) { 'de-de' }

        it 'renders correctly' do
          expect(result[:subject]).to eq('Test Ticket!')
          expect(result[:body]).to include('Ihr Zammad Helpdesk-Team')
          expect(result[:body]).to include('Benachrichtigungs-Einstellungen verwalten')
        end
      end
    end

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

          Unfortunately your email titled "Gruß aus Oberalteich" could not be delivered to one or more recipients.

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
          let(:locale)           { 'en' }
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

              Ihre E-Mail mit dem Betreff "Gruß aus Oberalteich" konnte leider nicht an einen oder mehrere Empfänger zugestellt werden.

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

  describe '#deliver' do
    subject(:result) do
      described_class.deliver(
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

      context 'without system notification signing enabled' do
        before do
          Setting.set('smime_sign_system_notifications', false)
          Setting.set('pgp_sign_system_notifications', false)
        end

        it 'does not parse the notification sender for secure mailing' do
          allow(described_class).to receive(:sender_email_address).and_call_original

          result

          expect(described_class).not_to have_received(:sender_email_address)
        end
      end

      context 'with active S/MIME integration' do
        before do
          SMIMECertificate.destroy_all

          Setting.set('smime_integration', true)
          Setting.set('smime_sign_system_notifications', false)
          Setting.set('pgp_integration', false)
          Setting.set('notification_sender', 'Zammad Helpdesk <smime1@example.com>')
        end

        context 'without system notification signing enabled' do
          before do
            create(:smime_certificate, :with_private, fixture: 'smime1@example.com')
          end

          it 'sends system notifications unsigned' do
            expect(result.mime_type).to eq('text/plain')
          end
        end

        context 'with signing certificate for notification sender' do
          before do
            Setting.set('smime_sign_system_notifications', true)
            create(:smime_certificate, :with_private, fixture: 'smime1@example.com')
          end

          it 'signs system notifications' do
            expect(result.mime_type).to eq('multipart/signed')
          end
        end

        context 'without signing certificate for notification sender' do
          before do
            Setting.set('smime_sign_system_notifications', true)
          end

          it 'sends system notifications unsigned' do
            expect(result.mime_type).to eq('text/plain')
          end
        end
      end

      context 'with active PGP integration' do
        before do
          PGPKey.destroy_all

          Setting.set('smime_integration', false)
          Setting.set('pgp_integration', true)
          Setting.set('pgp_sign_system_notifications', false)
          Setting.set('notification_sender', 'Zammad Helpdesk <pgp1@example.com>')
        end

        context 'without system notification signing enabled' do
          before do
            create(:pgp_key, :with_private, fixture: 'pgp1@example.com')
          end

          it 'sends system notifications unsigned' do
            expect(result.mime_type).to eq('text/plain')
          end
        end

        context 'with signing key for notification sender' do
          before do
            Setting.set('pgp_sign_system_notifications', true)
            create(:pgp_key, :with_private, fixture: 'pgp1@example.com')
          end

          it 'signs system notifications' do
            expect(result.mime_type).to eq('multipart/signed')
          end
        end

        context 'without signing key for notification sender' do
          before do
            Setting.set('pgp_sign_system_notifications', true)
          end

          it 'sends system notifications unsigned' do
            expect(result.mime_type).to eq('text/plain')
          end
        end

        context 'without an available PGP backend' do
          before do
            Setting.set('pgp_sign_system_notifications', true)
            allow(SecureMailing::PGP).to receive(:active?).and_return(false)
          end

          it 'sends system notifications unsigned' do
            expect(result.mime_type).to eq('text/plain')
          end
        end
      end

      context 'with S/MIME and PGP signing enabled' do
        before do
          SMIMECertificate.destroy_all
          PGPKey.destroy_all

          Setting.set('smime_integration', true)
          Setting.set('smime_sign_system_notifications', true)
          Setting.set('pgp_integration', true)
          Setting.set('pgp_sign_system_notifications', true)
          Setting.set('notification_sender', 'Zammad Helpdesk <pgp+smime-sender@example.com>')
        end

        context 'with S/MIME certificate and PGP key for notification sender' do
          before do
            create(:smime_certificate, :with_private, fixture: 'pgp+smime-sender@example.com')
            create(:pgp_key, :with_private, fixture: 'pgp+smime-sender@example.com')
          end

          it 'prefers S/MIME signing' do
            expect(result.content_type).to match(SecureMailing::SMIME::Incoming::EXPRESSION_SIGNATURE)
          end
        end

        context 'with only a PGP key for notification sender' do
          before do
            create(:pgp_key, :with_private, fixture: 'pgp+smime-sender@example.com')
          end

          it 'falls back to PGP signing' do
            expect(result.content_type).to include(SecureMailing::PGP::Incoming::SIGNATURE_CONTENT_TYPE)
          end
        end
      end

      context 'system notification signing edge cases' do
        before do
          Setting.set('pgp_integration', false)
          Setting.set('pgp_sign_system_notifications', false)
        end

        context 'with PGP signing enabled but integration disabled' do
          before do
            Setting.set('pgp_sign_system_notifications', true)
            Setting.set('notification_sender', 'Zammad Helpdesk <pgp1@example.com>')
            create(:pgp_key, :with_private, fixture: 'pgp1@example.com')
          end

          it 'delivers unsigned without crash' do
            expect(result.mime_type).to eq('text/plain')
          end
        end

        context 'with S/MIME signing' do
          before do
            Setting.set('smime_sign_system_notifications', true)
            Setting.set('notification_sender', 'Zammad Helpdesk <smime1@example.com>')
          end

          context 'with integration disabled' do
            before do
              create(:smime_certificate, :with_private, fixture: 'smime1@example.com')
            end

            it 'delivers unsigned without crash' do
              expect(result.mime_type).to eq('text/plain')
            end
          end

          context 'when signing fails during delivery' do
            before do
              Setting.set('smime_integration', true)
              create(:smime_certificate, :with_private, fixture: 'smime1@example.com')
            end

            it 'falls back to unsigned delivery and logs a warning' do
              allow(Rails.logger).to receive(:warn)
              call_count = 0
              allow_any_instance_of(Channel).to receive(:deliver) do |_channel, _params, _notification|
                call_count += 1
                raise SecureMailing::Backend::Handler::SigningError, 'Simulated signing failure' if call_count == 1

                Mail::Message.new
              end
              expect(result).to be_a(Mail::Message)
              expect(Rails.logger).to have_received(:warn)
                .with(%r{Signing notification.*failed.*sending unsigned})
            end
          end

          context 'when the transport fails during delivery' do
            before do
              Setting.set('smime_integration', true)
              create(:smime_certificate, :with_private, fixture: 'smime1@example.com')
            end

            it 'propagates the error instead of retrying unsigned' do
              deliver_calls = 0
              allow_any_instance_of(Channel).to receive(:deliver) do |_channel, _params, _notification|
                deliver_calls += 1
                raise StandardError, 'Connection refused'
              end

              expect { result }.to raise_error(StandardError, 'Connection refused')
              expect(deliver_calls).to eq(1)
            end
          end

          context 'when SigningError is raised during secure mailing check' do
            before do
              Setting.set('smime_integration', true)
              allow(SecureMailing::SMIME::NotificationOptions).to receive(:process)
                .and_raise(SecureMailing::Backend::Handler::SigningError, 'corrupt certificate')
            end

            it 'logs a warning and delivers unsigned' do
              allow(Rails.logger).to receive(:warn)
              expect(result.mime_type).to eq('text/plain')
              expect(Rails.logger).to have_received(:warn)
                .with(%r{Unable to sign system notification})
            end
          end
        end

        context 'with malformed notification sender address' do
          before do
            Setting.set('smime_sign_system_notifications', true)
            Setting.set('smime_integration', true)
            Setting.set('notification_sender', 'invalid without angle brackets')
          end

          it 'falls back to unsigned delivery and logs a warning' do
            allow(Rails.logger).to receive(:warn)
            expect(result.mime_type).to eq('text/plain')
            expect(Rails.logger).to have_received(:warn)
              .with(%r{Failed to parse notification sender address})
          end
        end
      end
    end

    context 'recipient without email address' do
      let(:user) { create(:agent, email: '') }

      it 'raises Exceptions::UnprocessableContent' do
        expect { result }.to raise_error(Exceptions::UnprocessableContent)
      end
    end
  end

  describe '#sender_email_address' do
    it 'returns the address for a valid sender' do
      expect(described_class.sender_email_address('Zammad Helpdesk <helpdesk@example.com>')).to eq('helpdesk@example.com')
    end

    it 'raises ArgumentError when the value parses to zero addresses' do
      expect { described_class.sender_email_address('Group: ;') }.to raise_error(ArgumentError, %r{No email address could be parsed})
    end

    it 'raises ArgumentError for a blank sender' do
      expect { described_class.sender_email_address('') }.to raise_error(ArgumentError, %r{No email address could be parsed})
    end
  end

  describe '#build_notification_sender' do
    it 'builds a sender for a valid address' do
      expect(described_class.build_notification_sender('Zammad Helpdesk <helpdesk@example.com>').email).to eq('helpdesk@example.com')
    end

    it 'returns nil and logs a warning when the value parses to zero addresses' do
      allow(Rails.logger).to receive(:warn)
      expect(described_class.build_notification_sender('Group: ;')).to be_nil
      expect(Rails.logger).to have_received(:warn).with(%r{Failed to parse notification sender address})
    end

    it 'returns nil and logs a warning for a malformed address' do
      allow(Rails.logger).to receive(:warn)
      expect(described_class.build_notification_sender('invalid without angle brackets')).to be_nil
      expect(Rails.logger).to have_received(:warn).with(%r{Failed to parse notification sender address})
    end
  end

end
