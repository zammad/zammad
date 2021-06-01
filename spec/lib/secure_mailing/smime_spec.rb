# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SecureMailing::SMIME do
  before do
    Setting.set('smime_integration', true)
  end

  let(:raw_body) { 'Some text' }

  let(:system_email_address) { 'smime1@example.com' }
  let(:customer_email_address) { 'smime2@example.com' }

  let(:sender_certificate_subject) { "/emailAddress=#{sender_email_address}/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com" }
  let(:recipient_certificate_subject) { "/emailAddress=#{recipient_email_address}/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com" }

  let(:expired_email_address) { 'expiredsmime1@example.com' }

  let(:ca_certificate_subject) { '/emailAddress=RootCA@example.com/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com' }

  let(:content_type) { 'text/plain' }

  def build_mail
    Channel::EmailBuild.build(
      from:         sender_email_address,
      to:           recipient_email_address,
      body:         raw_body,
      content_type: content_type,
      security:     security_preferences
    )
  end

  describe '.outgoing' do

    shared_examples 'HttpLog writer' do |status|

      it "logs #{status}" do
        expect do
          build_mail
        rescue
          # allow failures
        end.to change(HttpLog, :count).by(1)
        expect(HttpLog.last.attributes).to include('direction' => 'out', 'status' => status)
      end
    end

    let(:sender_email_address) { system_email_address }
    let(:recipient_email_address) { customer_email_address }

    context 'without security' do
      let(:security_preferences) do
        nil
      end

      it 'builds mail' do
        expect(build_mail.body).not_to match(SecureMailing::SMIME::Incoming::EXPRESSION_SIGNATURE)
        expect(build_mail.body).not_to match(SecureMailing::SMIME::Incoming::EXPRESSION_MIME)
        expect(build_mail.body).to eq(raw_body)
      end
    end

    context 'signing' do

      let(:security_preferences) do
        {
          type:       'S/MIME',
          sign:       {
            success: true,
          },
          encryption: {
            success: false,
          },
        }
      end

      context 'private key present' do

        let!(:sender_certificate) do
          create(:smime_certificate, :with_private, fixture: system_email_address)
        end

        it 'builds mail' do
          expect(build_mail.body).to match(SecureMailing::SMIME::Incoming::EXPRESSION_SIGNATURE)
        end

        it_behaves_like 'HttpLog writer', 'success'

        context 'expired certificate' do

          let(:system_email_address) { expired_email_address }

          it 'raises exception' do
            expect { build_mail }.to raise_error RuntimeError
          end

          it_behaves_like 'HttpLog writer', 'failed'
        end

        context 'when message is 7bit or 8bit encoded' do

          let(:mail) do
            smime_mail = build_mail

            mail = Channel::EmailParser.new.parse(smime_mail.to_s)
            SecureMailing.incoming(mail)

            mail
          end

          context 'when Content-Type is text/plain' do
            let(:raw_body) { "\r\n\r\n@john.doe, now known as John Dóe has accepted your invitation to join the Administrator / htmltest project.\r\n\r\nhttp://169.254.169.254:3000/root/htmltest\r\n\r\n-- \r\nYou're receiving this email because of your account on 169.254.169.254.\r\n\r\n\r\n\r\n" }

            it 'verifies' do
              expect(mail['x-zammad-article-preferences']['security']['sign']['success']).to be true
            end
          end

          context 'when Content-Type is text/html' do
            let(:content_type) { 'text/html' }
            let(:raw_body) { "<div><ul><li><p>an \nexample „Text“ with ümläütß. </p></li></ul></div>" }

            it 'verifies' do
              expect(mail['x-zammad-article-preferences']['security']['sign']['success']).to be true
            end
          end
        end

        context 'when certificate chain is present' do

          let(:system_email_address) { 'chain@example.com' }

          let!(:chain) do
            [
              sender_certificate,
              create(:smime_certificate, fixture: 'ChainCA'),
              create(:smime_certificate, fixture: 'IntermediateCA'),
              create(:smime_certificate, fixture: 'RootCA'),
            ]
          end

          let(:p7enc) do
            mail = Channel::EmailParser.new.parse(build_mail.to_s)
            OpenSSL::PKCS7.read_smime(mail[:raw])
          end

          it 'is included in the generated mail' do
            expect(p7enc.certificates).to eq(chain.map(&:parsed))
          end
        end
      end

      context 'no private key present' do
        before do
          create(:smime_certificate, fixture: system_email_address)
        end

        it 'raises exception' do
          expect { build_mail }.to raise_error RuntimeError
        end

        it_behaves_like 'HttpLog writer', 'failed'
      end
    end

    context 'encryption' do

      let(:security_preferences) do
        {
          type:       'S/MIME',
          sign:       {
            success: false,
          },
          encryption: {
            success: true,
          },
        }
      end

      context 'public key present' do
        before do
          create(:smime_certificate, fixture: recipient_email_address)
        end

        it 'builds mail' do
          mail = build_mail

          expect(mail['Content-Type'].value).to match(SecureMailing::SMIME::Incoming::EXPRESSION_MIME)
          expect(mail.body).not_to include(raw_body)
        end

        it_behaves_like 'HttpLog writer', 'success'

        context 'expired certificate' do

          let(:recipient_email_address) { expired_email_address }

          it 'raises exception' do
            expect { build_mail }.to raise_error RuntimeError
          end

          it_behaves_like 'HttpLog writer', 'failed'
        end
      end

      context 'no public key present' do

        it 'raises exception' do
          expect { build_mail }.to raise_error ActiveRecord::RecordNotFound
        end

        it_behaves_like 'HttpLog writer', 'failed'
      end
    end
  end

  describe '.incoming' do

    shared_examples 'HttpLog writer' do |status|

      it "logs #{status}" do
        expect do
          mail
        rescue
          # allow failures
        end.to change(HttpLog, :count).by(2)
        expect(HttpLog.last.attributes).to include('direction' => 'in', 'status' => status)
      end
    end

    let(:sender_email_address) { customer_email_address }
    let(:recipient_email_address) { system_email_address }

    context 'signature verification' do

      let(:allow_expired) { false }

      let(:security_preferences) do
        {
          type:       'S/MIME',
          sign:       {
            success:       true,
            allow_expired: allow_expired,
          },
          encryption: {
            success: false,
          },
        }
      end

      context 'sender certificate present' do

        before do
          create(:smime_certificate, :with_private, fixture: sender_email_address)
        end

        let(:mail) do
          smime_mail = build_mail

          mail = Channel::EmailParser.new.parse(smime_mail.to_s)
          SecureMailing.incoming(mail)

          mail
        end

        it 'verifies' do
          expect(mail[:body]).to include(raw_body)
          expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be true
          expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to eq(sender_certificate_subject)
          expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be false
          expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to be nil
        end

        it_behaves_like 'HttpLog writer', 'success'

        context 'expired' do

          # required to build mail with expired certificate
          let(:allow_expired) { true }
          let(:sender_email_address) { expired_email_address }

          it 'verifies with comment' do
            expect(mail[:body]).to include(raw_body)
            expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be true
            expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to include(expired_email_address).and include('expired')
            expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be false
            expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to be nil
          end

          it_behaves_like 'HttpLog writer', 'success'
        end
      end

      context 'no sender certificate' do

        let!(:sender_certificate) { create(:smime_certificate, :with_private, fixture: sender_email_address) }

        let(:mail) do
          smime_mail = build_mail
          mail       = Channel::EmailParser.new.parse(smime_mail.to_s)

          sender_certificate.destroy!

          SecureMailing.incoming(mail)

          mail
        end

        it 'fails' do
          expect(mail[:body]).to include(raw_body)
          expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be false
          expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to eq('Unable to find certificate for verification')
          expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be false
          expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to be nil
        end

        context 'public key present in signature' do

          let(:not_related_fixture) { 'smime3@example.com' }
          let!(:not_related_certificate) { create(:smime_certificate, fixture: not_related_fixture) }

          context 'not related certificate present' do

            it 'fails' do
              expect(mail[:body]).to include(raw_body)
              expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be false
              expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to eq('Unable to find certificate for verification')
              expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be false
              expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to be nil
            end

            it_behaves_like 'HttpLog writer', 'failed'

            context 'CA' do

              let(:not_related_fixture) { 'ExpiredCA' }

              it 'fails' do
                expect(mail[:body]).to include(raw_body)
                expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be false
                expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to eq('Unable to find certificate for verification')
                expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be false
                expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to be nil
              end

              it_behaves_like 'HttpLog writer', 'failed'
            end
          end

          context 'usage not prevented' do

            before do
              # remove OpenSSL::PKCS7::NOINTERN
              stub_const('SecureMailing::SMIME::Incoming::OPENSSL_PKCS7_VERIFY_FLAGS', OpenSSL::PKCS7::NOVERIFY)
            end

            it "won't perform verification" do
              expect(mail[:body]).to include(raw_body)
              expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be false
              expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to eq('Unable to find certificate for verification')
              expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be false
              expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to be nil
            end
          end
        end

        context 'root CA present' do

          before do
            create(:smime_certificate, fixture: ca_fixture)
          end

          let(:ca_fixture) { 'RootCA' }

          it 'verifies' do
            expect(mail[:body]).to include(raw_body)
            expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be true
            expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to eq(ca_certificate_subject)
            expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be false
            expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to be nil
          end

          it_behaves_like 'HttpLog writer', 'success'

          context 'expired' do
            let(:ca_fixture) { 'ExpiredCA' }

            it 'fails' do
              expect(mail[:body]).to include(raw_body)
              expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be false
              expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to eq('Unable to find certificate for verification')
              expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be false
              expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to be nil
            end

            it_behaves_like 'HttpLog writer', 'failed'

            context 'allowed' do

              let(:allow_expired) { true }

              # ATTENTION: expired CA is a special case where `allow_expired` does not count
              it 'fails' do
                expect(mail[:body]).to include(raw_body)
                expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be false
                expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to eq('Unable to find certificate for verification')
                expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be false
                expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to be nil
              end

              it_behaves_like 'HttpLog writer', 'failed'
            end
          end
        end

        context 'certificate chain' do

          let(:sender_email_address) { 'chain@example.com' }
          let(:ca_subject_chain) { ca_chain.reverse.map(&:subject).join(', ') }

          context 'incomplete certificate chain present' do

            before do
              create(:smime_certificate, fixture: 'RootCA')
              create(:smime_certificate, fixture: 'IntermediateCA')
            end

            it 'fails' do
              expect(mail[:body]).to include(raw_body)
              expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be false
              expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to eq('Unable to find certificate for verification')
              expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be false
              expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to be nil
            end
          end

          context 'certificate chain only partly present' do
            let(:ca_certificate_subject) { subject_chain }

            let!(:ca_chain) do
              [
                create(:smime_certificate, fixture: 'IntermediateCA'),
                create(:smime_certificate, fixture: 'ChainCA'),
              ]
            end

            it 'verifies' do
              expect(mail[:body]).to include(raw_body)
              expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be true
              expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to eq(ca_subject_chain)
              expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be false
              expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to be nil
            end
          end

          context 'complete certificate chain present' do

            let!(:ca_chain) do
              [
                create(:smime_certificate, fixture: 'RootCA'),
                create(:smime_certificate, fixture: 'IntermediateCA'),
                create(:smime_certificate, fixture: 'ChainCA'),
              ]
            end

            it 'verifies' do
              allow(Rails.logger).to receive(:warn)

              expect(mail[:body]).to include(raw_body)
              expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be true
              expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to eq(ca_subject_chain)
              expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be false
              expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to be nil

              expect(Rails.logger).not_to have_received(:warn).with(%r{#{Regexp.escape(ca_certificate_subject)}})
            end
          end
        end
      end
    end

    context 'decryption' do

      let(:allow_expired) { false }
      let(:security_preferences) do
        {
          type:       'S/MIME',
          sign:       {
            success: false,
          },
          encryption: {
            success:       true,
            allow_expired: allow_expired,
          },
        }
      end

      let!(:sender_certificate) { create(:smime_certificate, :with_private, fixture: sender_email_address) }
      let!(:recipient_certificate) { create(:smime_certificate, :with_private, fixture: recipient_email_address) }

      context 'private key present' do

        let(:mail) do
          smime_mail = build_mail

          mail = Channel::EmailParser.new.parse(smime_mail.to_s)
          SecureMailing.incoming(mail)

          mail
        end

        it 'decrypts' do
          expect(mail[:body]).to include(raw_body)
          expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be false
          expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to be nil
          expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be true
          expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to eq(recipient_certificate_subject)
        end

        it_behaves_like 'HttpLog writer', 'success'

        context 'expired allowed' do
          let(:allow_expired) { true }
          let(:system_email_address) { expired_email_address }

          it 'decrypts with comment' do
            expect(mail[:body]).to include(raw_body)
            expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be false
            expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to be nil
            expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be true
            expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to include(expired_email_address).and include('expired')
          end

          it_behaves_like 'HttpLog writer', 'success'
        end
      end

      context 'no private key present' do

        let(:mail) do
          smime_mail = build_mail

          mail = Channel::EmailParser.new.parse(smime_mail.to_s)

          sender_certificate.destroy!
          recipient_certificate.destroy!

          SecureMailing.incoming(mail)

          mail
        end

        it 'fails' do
          expect(mail[:body]).to include('no visible content')
          expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be false
          expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to be nil
          expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be false
          expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to eq('Unable to find private key to decrypt')
        end

        it_behaves_like 'HttpLog writer', 'failed'
      end
    end
  end

  describe '.retry' do
    let(:sender_email_address) { customer_email_address }
    let(:recipient_email_address) { system_email_address }

    let(:security_preferences) do
      {
        type:       'S/MIME',
        sign:       {
          success: true,
        },
        encryption: {
          success: true,
        },
      }
    end

    let(:mail) do
      sender_certificate    = create(:smime_certificate, :with_private, fixture: sender_email_address)
      recipient_certificate = create(:smime_certificate, :with_private, fixture: system_email_address)

      smime_mail = Channel::EmailBuild.build(
        from:         sender_email_address,
        to:           recipient_email_address,
        body:         raw_body,
        content_type: 'text/plain',
        security:     security_preferences,
        attachments:  [
          {
            content_type: 'text/plain',
            content:      'blub',
            filename:     'test-file1.txt',
          },
        ],
      )
      mail = Channel::EmailParser.new.parse(smime_mail.to_s)

      sender_certificate.destroy
      recipient_certificate.destroy

      mail
    end

    let!(:article) do
      _ticket, article, _user, _mail = Channel::EmailParser.new.process({}, mail['raw'] )
      article
    end

    context 'private key added' do
      before do
        create(:smime_certificate, :with_private, fixture: recipient_email_address)
        create(:smime_certificate, fixture: sender_email_address)
      end

      it 'succeeds' do
        SecureMailing.retry(article)

        expect(article.preferences[:security][:sign][:success]).to be true
        expect(article.preferences[:security][:sign][:comment]).to eq(sender_certificate_subject)
        expect(article.preferences[:security][:encryption][:success]).to be true
        expect(article.preferences[:security][:encryption][:comment]).to eq(recipient_certificate_subject)
        expect(article.body).to include(raw_body)
        expect(article.attachments.count).to eq(1)
        expect(article.attachments.first.filename).to eq('test-file1.txt')
      end

      context 'S/MIME activated' do

        before do
          Setting.set('smime_integration', false)
        end

        it 'succeeds' do
          Setting.set('smime_integration', true)

          SecureMailing.retry(article)

          expect(article.preferences[:security][:sign][:success]).to be true
          expect(article.preferences[:security][:sign][:comment]).to eq(sender_certificate_subject)
          expect(article.preferences[:security][:encryption][:success]).to be true
          expect(article.preferences[:security][:encryption][:comment]).to eq(recipient_certificate_subject)
          expect(article.body).to include(raw_body)
          expect(article.attachments.count).to eq(1)
          expect(article.attachments.first.filename).to eq('test-file1.txt')
        end
      end
    end
  end
end
