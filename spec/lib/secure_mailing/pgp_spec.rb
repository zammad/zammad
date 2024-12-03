# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SecureMailing::PGP, :aggregate_failures do
  before do
    Setting.set('pgp_integration', true)
  end

  let(:raw_body)    { 'Testing some Content' }
  let(:attachments) { [] }

  let(:system_email_address)      { 'pgp1@example.com' }
  let(:customer_email_address)    { 'pgp2@example.com' }
  let(:cc_customer_email_address) { 'pgp3@example.com' }
  let(:expired_email_address)     { 'expiredpgp1@example.com' }

  let(:content_type) { 'text/plain' }

  def build_mail
    Channel::EmailBuild.build(
      from:         sender_email_address,
      to:           recipient_email_address,
      cc:           cc_recipient_email_address,
      body:         raw_body,
      content_type: content_type,
      security:     security_preferences,
      attachments:  attachments
    )
  end

  describe 'outgoing' do
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

    let(:sender_email_address)       { system_email_address }
    let(:recipient_email_address)    { customer_email_address }
    let(:cc_recipient_email_address) { cc_customer_email_address }

    context 'without security' do
      let(:security_preferences) do
        nil
      end

      it 'builds mail' do
        expect(build_mail.body).not_to match(SecureMailing::PGP::Incoming::SIGNATURE_CONTENT_TYPE)
        expect(build_mail.body).to eq(raw_body)
      end
    end

    context 'with signing' do
      let(:security_preferences) do
        {
          type:       'PGP',
          sign:       {
            success: true,
          },
          encryption: {
            success: false,
          },
        }
      end

      context 'when private key present' do
        before do
          create(:pgp_key, :with_private, fixture: system_email_address)
        end

        it 'builds mail' do
          expect(build_mail.body).to match(SecureMailing::PGP::Incoming::SIGNATURE_CONTENT_TYPE)
        end

        it_behaves_like 'HttpLog writer', 'success'

        context 'with expired key' do

          let(:system_email_address) { expired_email_address }

          it 'raises exception' do
            expect { build_mail }.to raise_error ActiveRecord::RecordNotFound
          end

          it_behaves_like 'HttpLog writer', 'failed'
        end
      end

      context 'when no private key is present' do
        it 'raises exception' do
          expect { build_mail }.to raise_error ActiveRecord::RecordNotFound
        end

        it_behaves_like 'HttpLog writer', 'failed'
      end
    end

    context 'with encryption' do

      let(:security_preferences) do
        {
          type:       'PGP',
          sign:       {
            success: false,
          },
          encryption: {
            success: true,
          },
        }
      end

      context 'when all needed keys are present' do
        before do
          create(:pgp_key, :with_private, fixture: system_email_address)
          create(:pgp_key, fixture: recipient_email_address)
          create(:pgp_key, fixture: cc_recipient_email_address)
        end

        it 'builds mail' do
          mail = build_mail

          expect(mail['Content-Type'].value).to include('multipart/encrypted')
          expect(mail.body).not_to include(raw_body)
        end

        it_behaves_like 'HttpLog writer', 'success'
      end

      context 'when needed keys are not present' do
        it 'raises exception' do
          expect { build_mail }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context 'when one key is expired' do
        before do
          create(:pgp_key, :with_private, fixture: system_email_address)
          create(:pgp_key, fixture: recipient_email_address)
          create(:pgp_key, fixture: cc_recipient_email_address)
        end

        let(:customer_email_address) { expired_email_address }

        it 'raises exception' do
          expect { build_mail }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context 'when a key with multiple UIDs is present' do
        let(:customer_email_address) { 'multipgp2@example.com' }

        before do
          create(:pgp_key, :with_private, fixture: system_email_address)
          create(:pgp_key, fixture: recipient_email_address)
          create(:pgp_key, fixture: cc_customer_email_address)
        end

        it 'builds mail' do
          mail = build_mail

          expect(mail['Content-Type'].value).to include('multipart/encrypted')
          expect(mail.body).not_to include(raw_body)
        end

        it_behaves_like 'HttpLog writer', 'success'
      end
    end

    context 'with encryption and signing' do
      let(:security_preferences) do
        {
          type:       'PGP',
          sign:       {
            success: true,
          },
          encryption: {
            success: true,
          },
        }
      end

      before do
        create(:pgp_key, :with_private, fixture: system_email_address)
        create(:pgp_key, :with_private, fixture: recipient_email_address)
        create(:pgp_key, fixture: cc_customer_email_address)
      end

      it 'builds mail' do
        mail = build_mail

        expect(mail['Content-Type'].value).to include('multipart/encrypted')
        expect(mail.body).not_to include(raw_body)
      end

      context 'with inline image' do
        let(:article) do
          create(:ticket_article,
                 ticket: create(:ticket),
                 body:   '<div>some message article helper test1</div><div><img src="cid:15.274327094.140939@zammad.example.com"><br></div>')
        end

        let(:attachments) do
          create_list(
            :store,
            1,
            object:      'Ticket::Article',
            o_id:        article.id,
            data:        'fake',
            filename:    'inline_image.jpg',
            preferences: {
              'Content-Type'        => 'image/jpeg',
              'Mime-Type'           => 'image/jpeg',
              'Content-ID'          => '<15.274327094.140939>',
              'Content-Disposition' => 'inline',
            }
          )
        end

        let(:raw_body) do
          <<~MSG_HTML.chomp
            <!DOCTYPE html>
            <html>
              <head>
                <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
              </head>
              <body style="font-family:Geneva,Helvetica,Arial,sans-serif; font-size: 12px;">
                <div>some message article helper test1</div>
                <div><img src="cid:15.274327094.140939@zammad.example.com"><br></div>
              </body>
            </html>
          MSG_HTML
        end
        let(:content_type) { 'text/html' }

        it 'builds mail' do
          mail = build_mail

          expect(mail['Content-Type'].value).to include('multipart/encrypted')
        end
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

    shared_examples 'decrypting message content' do
      it 'decrypts message content' do
        expect(mail[:body]).to include(raw_body)
        expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be false
        expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to be_nil
        expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be true
        expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to eq ''
      end
    end

    shared_examples 'decrypting and verifying signature' do
      it 'decrypts and verifies signature' do
        expect(mail[:body]).to include(raw_body)
        expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be true
        expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to eq('Good signature')
        expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be true
        expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to eq ''
      end
    end

    let(:sender_email_address)       { system_email_address }
    let(:recipient_email_address)    { customer_email_address }
    let(:cc_recipient_email_address) { cc_customer_email_address }

    context 'when signature verification' do
      context 'when sender public key present' do

        before do
          create(:pgp_key, :with_private, fixture: sender_email_address)
        end

        let(:security_preferences) do
          {
            type:       'PGP',
            sign:       {
              success: true,
            },
            encryption: {
              success: false,
            },
          }
        end

        let(:mail) do
          pgp_mail = build_mail
          mail = Channel::EmailParser.new.parse(pgp_mail.to_s)
          SecureMailing.incoming(mail)

          mail
        end

        it 'verifies' do
          expect(mail[:body]).to include(raw_body)
          expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be true
          expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to eq 'Good signature'
          expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be false
          expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to be_nil
        end

        it_behaves_like 'HttpLog writer', 'success'

        context 'with html mail' do
          let(:raw_content) { '<div>&gt; Welcome!</div><div>&gt;</div><div>&gt; Thank you for installing Zammad. äöüß</div><div>&gt;</div>' }
          let(:raw_body) do
            <<~MSG_HTML.chomp
              <!DOCTYPE html>
              <html>
                <head>
                  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
                </head>
                <body style="font-family:Geneva,Helvetica,Arial,sans-serif; font-size: 12px;">
                  #{raw_content}
                </body>
              </html>
            MSG_HTML
          end
          let(:content_type) { 'text/html' }

          it 'verifies' do
            expect(mail[:body]).to eq(raw_content)
            expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be true
            expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to eq 'Good signature'
            expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be false
            expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to be_nil
          end
        end

        context 'when key is expired' do
          let(:mail) do
            # Import a mail which was created with a now expired key.
            pgp_mail = Rails.root.join('spec/fixtures/files/pgp/mail/mail-expired.box').read

            mail = Channel::EmailParser.new.parse(pgp_mail)
            SecureMailing.incoming(mail)

            mail
          end

          let(:sender_email_address) { expired_email_address }

          it 'not verified' do
            expect(mail[:body]).to include(raw_body)
            expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be true
            expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to eq 'Good signature'
            expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be false
            expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to be_nil
          end
        end
      end
    end

    context 'with decryption' do

      let(:security_preferences) do
        {
          type:       'PGP',
          sign:       {
            success: false,
          },
          encryption: {
            success: true,
          },
        }
      end

      let!(:sender_key)       { create(:pgp_key, :with_private, fixture: sender_email_address) }
      let!(:recipient_key)    { create(:pgp_key, :with_private, fixture: recipient_email_address) }
      let!(:cc_recipient_key) { create(:pgp_key, :with_private, fixture: cc_recipient_email_address) }

      context 'when private key present' do

        let(:mail) do
          pgp_mail = build_mail
          parsed_mail = Channel::EmailParser.new.parse(pgp_mail.to_s)

          SecureMailing.incoming(parsed_mail)

          parsed_mail
        end

        it_behaves_like 'decrypting message content'

        it_behaves_like 'HttpLog writer', 'success'

        context 'with existing second key for same uid' do
          let(:mail) do
            # Import a mail which was created with a now expired key.
            pgp_mail = Rails.root.join('spec/fixtures/files/pgp/mail/mail-other-key.box').read

            mail = Channel::EmailParser.new.parse(pgp_mail)
            SecureMailing.incoming(mail)

            mail
          end

          before do
            create(:pgp_key, :with_private, fixture: "#{recipient_email_address}-other")
          end

          it_behaves_like 'decrypting message content'
        end

        context 'with OCB key' do
          let(:recipient_email_address) { 'ocbpgp1@example.com' }

          let(:mail) do
            # Import a mail which was created with an OCB key.
            pgp_mail = Rails.root.join('spec/fixtures/files/pgp/mail/mail-ocb.box').read

            mail = Channel::EmailParser.new.parse(pgp_mail)
            SecureMailing.incoming(mail)

            mail
          end

          context 'with GPG version >= 2.2.27', if: SecureMailing::PGP::Tool.version >= '2.2.27' do
            it_behaves_like 'decrypting message content'
          end

          context 'with GPG version < 2.2.27', if: ENV['CI'] && SecureMailing::PGP::Tool.version < '2.2.27' do
            it 'provides an error message as an article comment' do
              expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be false
              expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to be_nil
              expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be false
              expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to eq 'There was an unknown PGP error. This PGP email was encrypted with a potentially unknown encryption algorithm.'
            end
          end
        end

        context 'when recipient is bcc only' do
          let(:mail) do
            create(:pgp_key, :with_private, fixture: 'zammad@localhost')

            # Import a mail which was created with bcc recipient only.
            pgp_mail = Rails.root.join('spec/fixtures/files/pgp/mail/mail-decrypt-bcc.box').read

            mail = Channel::EmailParser.new.parse(pgp_mail)
            SecureMailing.incoming(mail)

            mail
          end

          it_behaves_like 'decrypting message content'
        end
      end

      context 'with no private key present' do

        let(:mail) do
          pgp_mail = build_mail

          mail = Channel::EmailParser.new.parse(pgp_mail.to_s)

          sender_key.destroy!
          recipient_key.destroy!
          cc_recipient_key.destroy!

          SecureMailing.incoming(mail)

          mail
        end

        it 'fails' do
          expect(mail[:body]).to include('no visible content')
          expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be false
          expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to be_nil
          expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be false
          expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to eq('The private PGP key could not be found.')
        end

        it_behaves_like 'HttpLog writer', 'failed'
      end
    end

    context 'with signature verification and decryption' do
      let(:security_preferences) do
        {
          type:       'PGP',
          sign:       {
            success: true,
          },
          encryption: {
            success: true,
          },
        }
      end

      context 'when the mail is signed and encrypted separately' do
        before do
          create(:pgp_key, :with_private, fixture: sender_email_address)
          create(:pgp_key, :with_private, fixture: recipient_email_address)
          create(:pgp_key, fixture: cc_recipient_email_address)
        end

        let(:mail) do
          pgp_mail = build_mail

          mail = Channel::EmailParser.new.parse(pgp_mail.to_s)
          SecureMailing.incoming(mail)

          mail
        end

        it_behaves_like 'decrypting and verifying signature'
      end

      context 'when the mail is signed and encrypted (detached signature)' do
        let(:sender_key)       { create(:pgp_key, :with_private, fixture: sender_email_address) }
        let(:recipient_key)    { create(:pgp_key, :with_private, fixture: recipient_email_address) }
        let(:cc_recipient_key) { create(:pgp_key, :with_private, fixture: cc_recipient_email_address) }

        let(:mail) do
          # Import a mail that was signed + encrypted with a detached signature.
          pgp_mail = Rails.root.join('spec/fixtures/files/pgp/mail/mail-detached.box').read

          mail = Channel::EmailParser.new.parse(pgp_mail.to_s)
          SecureMailing.incoming(mail)

          mail
        end

        context 'when all keys are present' do
          before do
            sender_key
            recipient_key
            cc_recipient_key
          end

          it_behaves_like 'decrypting and verifying signature'
        end

        context 'when only cc recipient key is present for decryption' do
          before do
            sender_key
            cc_recipient_key
          end

          it_behaves_like 'decrypting and verifying signature'
        end

        context 'when only decryption key is present' do
          before do
            recipient_key
            cc_recipient_key
          end

          it 'decrypts, but verifies signature fails' do
            expect(mail[:body]).to include(raw_body)
            expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be false
            expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to eq('The public PGP key could not be found.')
            expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be true
            expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to eq ''
          end
        end

        context 'when all keys are present, but addresses are in upcase' do
          let(:mail) do
            # Import a mail and change the case of the sender address.
            pgp_mail = Rails.root.join('spec/fixtures/files/pgp/mail/mail-detached.box').read

            pgp_mail = pgp_mail.sub!('pgp1@example.com', 'PGP1@EXAMPLE.COM')
            pgp_mail = pgp_mail.sub!('pgp2@example.com', 'PGP2@EXAMPLE.COM')
            pgp_mail = pgp_mail.sub!('pgp3@example.com', 'PGP3@EXAMPLE.COM')

            mail = Channel::EmailParser.new.parse(pgp_mail.to_s)
            SecureMailing.incoming(mail)

            mail
          end

          before do
            sender_key
            recipient_key
            cc_recipient_key
          end

          it_behaves_like 'decrypting and verifying signature'
        end
      end

      context 'when the mail is signed and encrypted (attached signature)' do
        let(:sender_key)       { create(:pgp_key, :with_private, fixture: sender_email_address) }
        let(:recipient_key)    { create(:pgp_key, :with_private, fixture: recipient_email_address) }
        let(:cc_recipient_key) { create(:pgp_key, :with_private, fixture: cc_recipient_email_address) }

        let(:mail) do
          # Import a mail that was signed + encrypted with an attached signature.
          pgp_mail = Rails.root.join('spec/fixtures/files/pgp/mail/mail-attached.box').read

          mail = Channel::EmailParser.new.parse(pgp_mail.to_s)
          SecureMailing.incoming(mail)

          mail
        end

        context 'when all keys are present' do
          before do
            sender_key
            recipient_key
            cc_recipient_key
          end

          it_behaves_like 'decrypting and verifying signature'
        end

        context 'when only cc recipient key is present for decryption' do
          before do
            sender_key
            cc_recipient_key
          end

          it_behaves_like 'decrypting and verifying signature'
        end

        context 'when only decryption key is present' do
          before do
            recipient_key
            cc_recipient_key
          end

          it 'decrypts, but verifies signature fails' do
            expect(mail[:body]).to include(raw_body)
            expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be false
            expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to eq('The public PGP key could not be found.')
            expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be true
            expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to eq ''
          end
        end
      end

      context 'when the mail is signed and encrypted in the same go (combined)' do
        let(:sender_key)       { create(:pgp_key, :with_private, fixture: sender_email_address) }
        let(:recipient_key)    { create(:pgp_key, :with_private, fixture: recipient_email_address) }
        let(:cc_recipient_key) { create(:pgp_key, :with_private, fixture: cc_recipient_email_address) }

        let(:mail) do
          # Import a mail that was signed + encrypted with the same command.
          pgp_mail = Rails.root.join('spec/fixtures/files/pgp/mail/mail-combined.box').read

          mail = Channel::EmailParser.new.parse(pgp_mail.to_s)
          SecureMailing.incoming(mail)

          mail
        end

        context 'when all keys are present' do
          before do
            sender_key
            recipient_key
            cc_recipient_key
          end

          it_behaves_like 'decrypting and verifying signature'
        end

        context 'when only cc recipient key is present for decryption' do
          before do
            sender_key
            cc_recipient_key
          end

          it_behaves_like 'decrypting and verifying signature'
        end

        context 'when only decryption key is present' do
          before do
            recipient_key
            cc_recipient_key
          end

          it 'decrypts, but verifies signature fails' do
            expect(mail[:body]).to include(raw_body)
            expect(mail['x-zammad-article-preferences'][:security][:sign][:success]).to be false
            expect(mail['x-zammad-article-preferences'][:security][:sign][:comment]).to eq('The public PGP key could not be found.')
            expect(mail['x-zammad-article-preferences'][:security][:encryption][:success]).to be true
            expect(mail['x-zammad-article-preferences'][:security][:encryption][:comment]).to eq ''
          end
        end
      end

      context 'when domain alias support is used' do
        before do
          Setting.set('pgp_recipient_alias_configuration', true)

          create(:pgp_key, :with_private, fixture: 'pgp1@example.com', domain_alias: 'domain1.com')
          create(:pgp_key, :with_private, fixture: 'pgp2@example.com', domain_alias: 'domain2.com')
          create(:pgp_key, fixture: 'pgp3@example.com', domain_alias: 'domain3.com')
        end

        let(:system_email_address)      { 'pgp1@domain1.com' }
        let(:customer_email_address)    { 'pgp2@domain2.com' }
        let(:cc_customer_email_address) { 'pgp3@domain3.com' }

        let(:mail) do
          pgp_mail = build_mail
          mail = Channel::EmailParser.new.parse(pgp_mail.to_s)
          SecureMailing.incoming(mail)

          mail
        end

        it_behaves_like 'decrypting and verifying signature'
      end
    end
  end

  describe '.required_version?' do
    context 'with GnuPG being present on the system' do
      it 'succeeds' do
        expect(described_class.required_version?).to be true
      end
    end

    context 'without GnuPG being present on the system' do
      it 'fails' do
        allow(SecureMailing::PGP::Tool).to receive(:version).and_raise(Errno::ENOENT)
        expect(described_class.required_version?).to be false
      end
    end

    context 'with and outdated version of GnuPG' do
      it 'fails' do
        allow(SecureMailing::PGP::Tool).to receive(:version).and_return('1.8.0')
        expect(described_class.required_version?).to be false
      end
    end
  end

  describe '.retry' do
    let(:sender_email_address)       { customer_email_address }
    let(:recipient_email_address)    { system_email_address }
    let(:cc_recipient_email_address) { nil }

    let(:security_preferences) do
      {
        type:       'PGP',
        sign:       {
          success: false,
        },
        encryption: {
          success: true,
        },
      }
    end

    let(:mail) do
      sender_pgp_key    = create(:pgp_key, :with_private, fixture: sender_email_address)
      recipient_pgp_key = create(:pgp_key, :with_private, fixture: system_email_address)

      pgp_mail = Channel::EmailBuild.build(
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
      mail = Channel::EmailParser.new.parse(pgp_mail.to_s)

      sender_pgp_key.destroy
      recipient_pgp_key.destroy

      mail
    end

    let!(:article) do
      _ticket, article, _user, _mail = Channel::EmailParser.new.process({}, mail['raw'])
      article
    end

    context 'when private key added' do
      before do
        create(:pgp_key, :with_private, fixture: recipient_email_address)
      end

      it 'succeeds' do
        SecureMailing.retry(article)

        expect(article.preferences[:security][:sign][:success]).to be false
        expect(article.preferences[:security][:sign][:comment]).to be_nil
        expect(article.preferences[:security][:encryption][:success]).to be true
        expect(article.preferences[:security][:encryption][:comment]).to eq ''
        expect(article.body).to include(raw_body)
        expect(article.attachments.count).to eq(1)
        expect(article.attachments.first.filename).to eq('test-file1.txt')
      end

      context 'when PGP activated' do

        before do
          Setting.set('pgp_integration', false)
        end

        it 'succeeds' do
          Setting.set('pgp_integration', true)

          SecureMailing.retry(article)

          expect(article.preferences[:security][:sign][:success]).to be false
          expect(article.preferences[:security][:sign][:comment]).to be_nil
          expect(article.preferences[:security][:encryption][:success]).to be true
          expect(article.preferences[:security][:encryption][:comment]).to eq ''
          expect(article.body).to include(raw_body)
          expect(article.attachments.count).to eq(1)
          expect(article.attachments.first.filename).to eq('test-file1.txt')
        end
      end
    end
  end
end
