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

    context 'with password_reset and ticket notification templates' do
      let(:groups) { Group.where(name: 'Users') }
      let(:roles)  { Role.where(name: 'Agent') }
      let(:agent1) do
        User.create!(
          login:         'notification-template-agent1@example.com',
          firstname:     'Notification<b>xxx</b>',
          lastname:      'Agent1<b>yyy</b>',
          email:         'notification-template-agent1@example.com',
          password:      'agentpw',
          active:        true,
          roles:         roles,
          groups:        groups,
          preferences:   {
            locale: 'de-de',
          },
          updated_by_id: 1,
          created_by_id: 1,
        )
      end
      let(:agent_current_user) do
        User.create!(
          login:         'notification-template-current_user@example.com',
          firstname:     'Notification Current',
          lastname:      'User',
          email:         'notification-template-current_user@example.com',
          password:      'agentpw',
          active:        true,
          roles:         roles,
          groups:        groups,
          preferences:   {
            locale: 'de-de',
          },
          updated_by_id: 1,
          created_by_id: 1,
        )
      end

      before do
        Translation.sync_locale_from_po('de-de')
      end

      context 'with password_reset template' do
        let(:result) do
          described_class.template(
            template: 'password_reset',
            locale:   locale,
            objects:  {
              user: agent1,
            },
          )
        end

        context 'with locale de-de' do
          let(:locale) { 'de-de' }

          it 'renders the German notification', :aggregate_failures do
            expect(result[:subject]).to include('Zurücksetzen Ihres')
            expect(result[:body]).to include('wir haben eine Anfrage zum Zurücksetzen')
            expect(result[:body]).to include('Ihr')
            expect(result[:body]).to include('Notification&lt;b&gt;xxx&lt;/b&gt;')
            expect(result[:body]).not_to include('Your')
          end
        end

        context 'with locale de' do
          let(:locale) { 'de' }

          it 'renders the German notification', :aggregate_failures do
            expect(result[:subject]).to include('Zurücksetzen Ihres')
            expect(result[:body]).to include('wir haben eine Anfrage zum Zurücksetzen')
            expect(result[:body]).to include('Ihr')
            expect(result[:body]).to include('Notification&lt;b&gt;xxx&lt;/b&gt;')
            expect(result[:body]).not_to include('Your')
          end
        end

        context 'with a not existing locale' do
          let(:locale) { 'xx-us' }

          it 'falls back to the English notification', :aggregate_failures do
            expect(result[:subject]).to include('Reset your')
            expect(result[:body]).to include('We received a request to reset the password')
            expect(result[:body]).to include('Your')
            expect(result[:body]).to include('Notification&lt;b&gt;xxx&lt;/b&gt;')
            expect(result[:body]).not_to include('Ihr')
          end
        end
      end

      context 'with ticket notification templates' do
        let(:ticket) do
          Ticket.create(
            group_id:      Group.lookup(name: 'Users').id,
            customer_id:   User.lookup(email: 'nicole.braun@zammad.org').id,
            owner_id:      User.lookup(login: '-').id,
            title:         'Welcome to Zammad!',
            state_id:      Ticket::State.lookup(name: 'new').id,
            priority_id:   Ticket::Priority.lookup(name: '2 normal').id,
            updated_by_id: 1,
            created_by_id: 1,
          )
        end
        let(:result) do
          described_class.template(
            template: template,
            locale:   locale,
            objects:  {
              ticket:       ticket,
              article:      article,
              recipient:    agent1,
              current_user: agent_current_user,
              changes:      changes,
            },
          )
        end

        context 'with ticket_create template' do
          let(:template) { 'ticket_create' }
          let(:changes)  { {} }
          let(:article) do
            Ticket::Article.create(
              ticket_id:     ticket.id,
              type_id:       Ticket::Article::Type.lookup(name: 'phone').id,
              sender_id:     Ticket::Article::Sender.lookup(name: 'Customer').id,
              from:          'Zammad Feedback <feedback@zammad.org>',
              content_type:  'text/plain',
              body:          "Welcome!\n<b>test123</b>",
              internal:      false,
              updated_by_id: 1,
              created_by_id: 1,
            )
          end

          context 'with locale xx-us' do
            let(:locale) { 'xx-us' }

            it 'renders the English notification with an escaped article body', :aggregate_failures do
              expect(result[:subject]).to include('New ticket')
              expect(result[:body]).to include('Notification&lt;b&gt;xxx&lt;/b&gt;')
              expect(result[:body]).to include('has been created by')
              expect(result[:body]).to include('&lt;b&gt;test123&lt;/b&gt;')
              expect(result[:body]).to include('Manage your notification settings')
              expect(result[:body]).not_to include('Dein')
              expect(result[:body]).not_to include('longname')
              expect(result[:body]).to include('Current User')
            end
          end

          context 'with locale de-de' do
            let(:locale) { 'de-de' }

            it 'renders the German notification with an escaped article body', :aggregate_failures do
              expect(result[:subject]).to include('Neues Ticket')
              expect(result[:body]).to include('Notification&lt;b&gt;xxx&lt;/b&gt;')
              expect(result[:body]).to include('ein neues Ticket')
              expect(result[:body]).to include('&lt;b&gt;test123&lt;/b&gt;')
              expect(result[:body]).to include(Translation.translate('de-de', 'Manage your notification settings'))
              expect(result[:body]).not_to include('Your')
              expect(result[:body]).not_to include('longname')
              expect(result[:body]).to include('Current User')
            end
          end
        end

        context 'with ticket_update template' do
          let(:template) { 'ticket_update' }
          let(:changes) do
            {
              state: %w[aaa bbb],
              group: %w[xxx yyy],
            }
          end
          let(:article) do
            Ticket::Article.create(
              ticket_id:     ticket.id,
              type_id:       Ticket::Article::Type.lookup(name: 'phone').id,
              sender_id:     Ticket::Article::Sender.lookup(name: 'Customer').id,
              from:          'Zammad Feedback <feedback@zammad.org>',
              content_type:  'text/html',
              body:          "Welcome!\n<b>test123</b>",
              internal:      false,
              updated_by_id: 1,
              created_by_id: 1,
            )
          end

          context 'with locale xx-us' do
            let(:locale) { 'xx-us' }

            it 'renders the English notification with an unescaped article body', :aggregate_failures do
              expect(result[:subject]).to include('Updated ticket')
              expect(result[:body]).to include('Notification&lt;b&gt;xxx&lt;/b&gt;')
              expect(result[:body]).to include('has been updated by')
              expect(result[:body]).to include('<b>test123</b>')
              expect(result[:body]).to include('Manage your notification settings')
              expect(result[:body]).not_to include('Dein')
              expect(result[:body]).not_to include('longname')
              expect(result[:body]).to include('Current User')
            end
          end

          context 'with locale de-de' do
            let(:locale) { 'de-de' }

            it 'renders the German notification with an unescaped article body', :aggregate_failures do
              expect(result[:subject]).to include('Aktualisiertes Ticket')
              expect(result[:body]).to include('Notification&lt;b&gt;xxx&lt;/b&gt;')
              expect(result[:body]).to include('wurde von')
              expect(result[:body]).to include('<b>test123</b>')
              expect(result[:body]).to include(Translation.translate('de-de', 'Manage your notification settings'))
              expect(result[:body]).not_to include('Your')
              expect(result[:body]).not_to include('longname')
              expect(result[:body]).to include('Current User')
            end
          end

          context 'without a given locale, with default locale de-de' do
            let(:result) do
              described_class.template(
                template: template,
                objects:  {
                  ticket:       ticket,
                  article:      article,
                  recipient:    agent1,
                  current_user: agent_current_user,
                  changes:      changes,
                },
              )
            end

            before do
              Setting.set('locale_default', 'de-de')
            end

            it 'renders the German notification', :aggregate_failures do
              expect(result[:subject]).to include('Aktualisiertes Ticket')
              expect(result[:body]).to include('Notification&lt;b&gt;xxx&lt;/b&gt;')
              expect(result[:body]).to include('wurde von')
              expect(result[:body]).to include('<b>test123</b>')
              expect(result[:body]).to include(Translation.translate('de-de', 'Manage your notification settings'))
              expect(result[:body]).not_to include('Your')
              expect(result[:body]).not_to include('longname')
              expect(result[:body]).to include('Current User')
            end
          end

          context 'without a given locale, with a not existing default locale' do
            let(:result) do
              described_class.template(
                template: template,
                objects:  {
                  ticket:       ticket,
                  article:      article,
                  recipient:    agent1,
                  current_user: agent_current_user,
                  changes:      changes,
                },
              )
            end

            before do
              Setting.set('locale_default', 'not_existing')
            end

            it 'falls back to the English notification', :aggregate_failures do
              expect(result[:subject]).to include('Updated ticket')
              expect(result[:body]).to include('Notification&lt;b&gt;xxx&lt;/b&gt;')
              expect(result[:body]).to include('has been updated by')
              expect(result[:body]).to include('<b>test123</b>')
              expect(result[:body]).to include('Manage your notification settings')
              expect(result[:body]).not_to include('Dein')
              expect(result[:body]).not_to include('longname')
              expect(result[:body]).to include('Current User')
            end
          end

          context 'without a given locale, with default locale pt-br' do
            let(:result) do
              described_class.template(
                template: template,
                objects:  {
                  ticket:       ticket,
                  article:      article,
                  recipient:    agent1,
                  current_user: agent_current_user,
                  changes:      changes,
                },
              )
            end

            before do
              Setting.set('locale_default', 'pt-br')
            end

            it 'renders the Portuguese notification', :aggregate_failures do
              expect(result[:subject]).to include('atualizado')
              expect(result[:body]).to include('Notification&lt;b&gt;xxx&lt;/b&gt;')
              expect(result[:body]).to include('foi atualizado por')
              expect(result[:body]).to include('<b>test123</b>')
              expect(result[:body]).to include(Translation.translate('pt-br', 'Manage your notification settings'))
              expect(result[:body]).not_to include('Dein')
              expect(result[:body]).not_to include('longname')
              expect(result[:body]).to include('Current User')
            end
          end
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

    context 'with content_type variations' do
      let(:user) { User.find(2) }

      context 'with a blank content_type' do
        subject(:result) do
          described_class.deliver(
            recipient:    user,
            subject:      'some subject',
            body:         'some body',
            content_type: '',
          )
        end

        it 'renders a plain text mail', :aggregate_failures do
          expect(result.to_s).to include('some body')
          expect(result.to_s).to include('text/plain')
          expect(result.to_s).not_to include('text/html')
        end
      end

      context 'with a text/plain content_type' do
        subject(:result) do
          described_class.deliver(
            recipient:    user,
            subject:      'some subject',
            body:         'some body',
            content_type: 'text/plain',
          )
        end

        it 'renders a plain text mail', :aggregate_failures do
          expect(result.to_s).to include('some body')
          expect(result.to_s).to include('text/plain')
          expect(result.to_s).not_to include('text/html')
        end
      end

      context 'with a text/html content_type' do
        subject(:result) do
          described_class.deliver(
            recipient:    user,
            subject:      'some subject',
            body:         'some <span>body</span>',
            content_type: 'text/html',
          )
        end

        it 'renders a multipart mail with plain and html parts', :aggregate_failures do
          expect(result.to_s).to include('some body')
          expect(result.to_s).to include('text/plain')
          expect(result.to_s).to include('<span>body</span>')
          expect(result.to_s).to include('text/html')
        end
      end

      context 'with inline and attached files' do
        subject(:result) do
          described_class.deliver(
            recipient:    user,
            subject:      'some subject',
            body:         'some <span>body</span><img style="width: 85.5px; height: 49.5px" src="cid:15.274327094.140938@zammad.example.com">asdasd<br>',
            content_type: 'text/html',
            attachments:  attachments,
          )
        end

        let(:attachments) do
          [
            Store.create!(
              object:        'TestMailer',
              o_id:          1,
              data:          'content_file1_normally_should_be_an_image',
              filename:      'some_file1.jpg',
              preferences:   {
                'Content-Type'        => 'image/jpeg',
                'Mime-Type'           => 'image/jpeg',
                'Content-ID'          => '15.274327094.140938@zammad.example.com',
                'Content-Disposition' => 'inline'
              },
              created_by_id: 1,
            ),
            Store.create!(
              object:        'TestMailer',
              o_id:          1,
              data:          'content_file2',
              filename:      'some_file2.txt',
              preferences:   {
                'Content-Type' => 'text/stream',
                'Mime-Type'    => 'text/stream',
              },
              created_by_id: 1,
            ),
          ]
        end

        it 'includes the inline image and the plain attachment', :aggregate_failures do
          expect(result.to_s).to include('some body')
          expect(result.to_s).to include('text/plain')
          expect(result.to_s).to include('<span>body</span>')
          expect(result.to_s).to include('text/html')
          expect(result.to_s).to include('Content-Type: image/jpeg')
          expect(result.to_s).to include('Content-Disposition: inline')
          expect(result.to_s).to include('Content-ID: <15.274327094.140938@zammad.example.com>')
          expect(result.to_s).to include('text/stream')
          expect(result.to_s).to include('some_file2.txt')
        end
      end
    end
  end

  describe '#notification_settings' do
    let(:roles)  { Role.where(name: 'Agent') }
    let(:groups) { Group.all }
    let(:agent1) do
      User.create!(
        login:         'notification-settings-agent1@example.com',
        firstname:     'Notification<b>xxx</b>',
        lastname:      'Agent1',
        email:         'notification-settings-agent1@example.com',
        password:      'agentpw',
        active:        true,
        roles:         roles,
        groups:        groups,
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:agent2) do
      User.create!(
        login:         'notification-settings-agent2@example.com',
        firstname:     'Notification<b>xxx</b>',
        lastname:      'Agent2',
        email:         'notification-settings-agent2@example.com',
        password:      'agentpw',
        active:        true,
        roles:         roles,
        groups:        groups,
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:group_notification_setting) do
      Group.create!(
        name:          'NotificationSetting',
        updated_by_id: 1,
        created_by_id: 1,
      )
    end

    # ticket1: 'Users' group, unowned
    # ticket2: 'Users' group, owned by agent1
    # ticket3: dedicated group, unowned
    # ticket4: dedicated group, owned by agent1
    let(:ticket1) do
      Ticket.create(
        group_id:      Group.lookup(name: 'Users').id,
        customer_id:   User.lookup(email: 'nicole.braun@zammad.org').id,
        owner_id:      User.lookup(login: '-').id,
        title:         'Notification Settings Test 1!',
        state_id:      Ticket::State.lookup(name: 'new').id,
        priority_id:   Ticket::Priority.lookup(name: '2 normal').id,
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:ticket2) do
      Ticket.create(
        group_id:      Group.lookup(name: 'Users').id,
        customer_id:   User.lookup(email: 'nicole.braun@zammad.org').id,
        owner_id:      agent1.id,
        title:         'Notification Settings Test 2!',
        state_id:      Ticket::State.lookup(name: 'new').id,
        priority_id:   Ticket::Priority.lookup(name: '2 normal').id,
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:ticket3) do
      Ticket.create(
        group_id:      group_notification_setting.id,
        customer_id:   User.lookup(email: 'nicole.braun@zammad.org').id,
        owner_id:      User.lookup(login: '-').id,
        title:         'Notification Settings Test 1!',
        state_id:      Ticket::State.lookup(name: 'new').id,
        priority_id:   Ticket::Priority.lookup(name: '2 normal').id,
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:ticket4) do
      Ticket.create(
        group_id:      group_notification_setting.id,
        customer_id:   User.lookup(email: 'nicole.braun@zammad.org').id,
        owner_id:      agent1.id,
        title:         'Notification Settings Test 2!',
        state_id:      Ticket::State.lookup(name: 'new').id,
        priority_id:   Ticket::Priority.lookup(name: '2 normal').id,
        updated_by_id: 1,
        created_by_id: 1,
      )
    end

    context 'when group_ids is unset (nil) for both agents' do
      it 'notifies both agents about all four tickets', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        agent1.preferences[:notification_config][:group_ids] = nil
        agent1.save
        travel 30.seconds

        result = described_class.notification_settings(agent1, ticket1, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        result = described_class.notification_settings(agent1, ticket2, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        result = described_class.notification_settings(agent1, ticket3, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        result = described_class.notification_settings(agent1, ticket4, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        agent2.preferences[:notification_config][:group_ids] = nil
        agent2.save
        travel 30.seconds

        result = described_class.notification_settings(agent2, ticket1, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        result = described_class.notification_settings(agent2, ticket2, 'create')
        expect(result).to be_nil

        result = described_class.notification_settings(agent2, ticket3, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        result = described_class.notification_settings(agent2, ticket4, 'create')
        expect(result).to be_nil

        travel_back
      end
    end

    context 'when group_ids is an empty array (no group selection) for both agents' do
      it 'notifies both agents about all four tickets', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        agent1.preferences[:notification_config][:group_ids] = []
        agent1.save
        travel 30.seconds

        result = described_class.notification_settings(agent1, ticket1, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        result = described_class.notification_settings(agent1, ticket2, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        result = described_class.notification_settings(agent1, ticket3, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        result = described_class.notification_settings(agent1, ticket4, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        agent2.preferences[:notification_config][:group_ids] = []
        agent2.save
        travel 30.seconds

        result = described_class.notification_settings(agent2, ticket1, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        result = described_class.notification_settings(agent2, ticket2, 'create')
        expect(result).to be_nil

        result = described_class.notification_settings(agent2, ticket3, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        result = described_class.notification_settings(agent2, ticket4, 'create')
        expect(result).to be_nil

        travel_back
      end
    end

    context "when group_ids is ['-'] for both agents" do
      it 'notifies both agents about all four tickets', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        agent1.preferences[:notification_config][:group_ids] = ['-']
        agent1.save
        travel 30.seconds

        result = described_class.notification_settings(agent1, ticket1, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        result = described_class.notification_settings(agent1, ticket2, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        result = described_class.notification_settings(agent1, ticket3, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        result = described_class.notification_settings(agent1, ticket4, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        agent2.preferences[:notification_config][:group_ids] = ['-']
        agent2.save
        travel 30.seconds

        result = described_class.notification_settings(agent2, ticket1, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        result = described_class.notification_settings(agent2, ticket2, 'create')
        expect(result).to be_nil

        result = described_class.notification_settings(agent2, ticket3, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        result = described_class.notification_settings(agent2, ticket4, 'create')
        expect(result).to be_nil

        travel_back
      end
    end

    context 'when group_ids is restricted to a dedicated group' do
      it 'notifies only for tickets in the selected group, and for agent1 also for tickets they own', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        agent1.preferences[:notification_config][:group_ids] = [Group.lookup(name: 'Users').id]
        agent1.save
        travel 30.seconds

        result = described_class.notification_settings(agent1, ticket1, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        result = described_class.notification_settings(agent1, ticket2, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        result = described_class.notification_settings(agent1, ticket3, 'create')
        expect(result).to be_nil

        result = described_class.notification_settings(agent1, ticket4, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        agent2.preferences[:notification_config][:group_ids] = [Group.lookup(name: 'Users').id]
        agent2.save
        travel 30.seconds

        result = described_class.notification_settings(agent2, ticket1, 'create')
        expect(result[:channels][:online]).to be(true)
        expect(result[:channels][:email]).to be(true)

        result = described_class.notification_settings(agent2, ticket2, 'create')
        expect(result).to be_nil

        result = described_class.notification_settings(agent2, ticket3, 'create')
        expect(result).to be_nil
        expect(result).to be_nil

        result = described_class.notification_settings(agent2, ticket4, 'create')
        expect(result).to be_nil

        travel_back
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
