# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Secure mailing', authenticated_as: :authenticate, type: :system do
  shared_examples 'secure mailing received mail' do
    context 'when receiving mail' do

      describe 'article meta information' do

        context 'when result is success' do
          let(:article) do
            create(:ticket_article, preferences: {
                     security: {
                       type:       'S/MIME',
                       encryption: {
                         success: true,
                         comment: 'COMMENT_ENCRYPT_SUCCESS',
                       },
                       sign:       {
                         success: true,
                         comment: 'COMMENT_SIGN_SUCCESS',
                       },
                     }
                   }, ticket: ticket)
          end

          it 'shows encryption/sign information' do

            visit "#ticket/zoom/#{article.ticket.id}"

            within :active_ticket_article, article do
              within '.alert--blank' do
                expect(page).to have_css('svg.icon-lock')
                  .and(have_css('svg.icon-signed'))
              end
            end

            open_article_meta

            within :active_ticket_article, article do
              within '.article-meta-value', text: %r{S/MIME} do
                expect(page).to have_css('span', text: 'Encrypted')
                  .and(have_css('span', text: 'Signed'))
                  .and(have_css('span[title=COMMENT_ENCRYPT_SUCCESS]'))
                  .and(have_css('span[title=COMMENT_SIGN_SUCCESS]'))
              end
            end
          end
        end

        context 'when result is sign block only' do
          let(:article) do
            create(:ticket_article, preferences: {
                     security: {
                       type: 'S/MIME',
                       sign: {
                         success: true,
                         comment: 'COMMENT_SIGN_SUCCESS',
                       },
                     }
                   }, ticket: ticket)
          end

          it 'shows sign but no encryption information' do
            visit "#ticket/zoom/#{article.ticket.id}"

            within :active_ticket_article, article do
              within '.alert--blank' do
                expect(page).to have_no_css('svg.icon-lock')
                  .and(have_css('svg.icon-signed'))
              end
            end

            open_article_meta

            within :active_ticket_article, article do
              within '.article-meta-value', text: %r{S/MIME} do
                expect(page).to have_no_css('span', text: 'Encrypted')
                  .and(have_no_css('span', text: 'Encryption error'))
                  .and(have_css('span', text: 'Signed'))
                  .and(have_css('span[title=COMMENT_SIGN_SUCCESS]'))
              end
            end
          end
        end

        context 'when result is encryption block and sign block without comment' do
          let(:article) do
            create(:ticket_article, preferences: {
                     security: {
                       type:       'S/MIME',
                       encryption: {
                         success: true,
                         comment: 'COMMENT_ENCRYPT_SUCCESS',
                       },
                       sign:       {
                         success: false
                       },
                     }
                   }, ticket: ticket)
          end

          it 'shows encryption but no sign information' do
            visit "#ticket/zoom/#{article.ticket.id}"

            within :active_ticket_article, article do
              within '.alert--blank' do
                expect(page).to have_css('svg.icon-lock')
                  .and(have_no_css('svg.icon-signed'))
              end
            end

            open_article_meta

            within :active_ticket_article, article do
              within '.article-meta-value', text: %r{S/MIME} do
                expect(page).to have_no_css('span', text: 'Signed')
                  .and(have_no_css('span', text: 'Sign error'))
                  .and(have_no_css('span', text: 'Encryption error'))
                  .and(have_css('span', text: 'Encrypted'))
                  .and(have_css('span[title=COMMENT_ENCRYPT_SUCCESS]'))
              end
            end
          end
        end

        context 'when result is error' do
          let(:article) do
            create(:ticket_article, preferences: {
                     security: {
                       type:       'S/MIME',
                       encryption: {
                         success: false,
                         comment: 'Encryption failed because XXX',
                       },
                       sign:       {
                         success: false,
                         comment: 'Sign failed because XXX',
                       },
                     }
                   }, ticket: ticket)
          end

          it 'shows create information about encryption/sign failed' do
            visit "#ticket/zoom/#{article.ticket.id}"

            within :active_ticket_article, article do
              expect(page).to have_css('svg.icon-not-signed')

              expect(page).to have_css('div.alert.alert--warning', text: 'Encryption failed because XXX')
                .and(have_css('div.alert.alert--warning', text: 'Sign failed because XXX'))
            end

            open_article_meta

            within :active_ticket_article, article do
              within '.article-meta-value', text: %r{S/MIME} do
                expect(page).to have_css('span', text: 'Encryption error')
                  .and(have_css('span', text: 'Sign error'))
                  .and(have_css('span[title="Encryption failed because XXX"]'))
                  .and(have_css('span[title="Sign failed because XXX"]'))
              end
            end
          end
        end
      end

      context 'when certificate not present at time of arrival' do
        let(:mail) do
          secure_mailing_1 = create(secure_mailing_factory_name, :with_private, fixture: system_email_address)
          secure_mailing_2 = create(secure_mailing_factory_name, :with_private, fixture: sender_email_address)

          mail = Channel::EmailBuild.build(
            from:         sender_email_address,
            to:           system_email_address,
            body:         'somebody with some text',
            content_type: 'text/plain',
            security:     {
              type:       secure_mailing_type_name,
              sign:       {
                success: true,
              },
              encryption: {
                success: true,
              },
            },
          )

          secure_mailing_1.destroy
          secure_mailing_2.destroy

          mail
        end

        it 'does retry successfully' do
          parsed_mail = Channel::EmailParser.new.parse(mail.to_s)
          ticket, article, _user, _mail = Channel::EmailParser.new.process({ group_id: group.id }, parsed_mail['raw'])
          expect(Ticket::Article.find(article.id).body).to eq('no visible content')

          create(secure_mailing_factory_name, fixture: sender_email_address)
          create(secure_mailing_factory_name, :with_private, fixture: system_email_address)

          visit "#ticket/zoom/#{ticket.id}"
          expect(page).to have_no_css('.article-content', text: 'somebody with some text')
          click '.js-securityRetryProcess'
          expect(page).to have_css('.article-content', text: 'somebody with some text')
        end

        it 'does fail on retry (S/MIME function buttons no longer working in tickets #3957)' do
          parsed_mail = Channel::EmailParser.new.parse(mail.to_s)
          ticket, article, _user, _mail = Channel::EmailParser.new.process({ group_id: group.id }, parsed_mail['raw'])
          expect(Ticket::Article.find(article.id).body).to eq('no visible content')

          visit "#ticket/zoom/#{ticket.id}"
          expect(page).to have_no_css('.article-content', text: 'somebody with some text')
          click '.js-securityRetryProcess'
          expect(page).to have_css('#notify', text: secure_mailing_decryption_failed_message)
        end
      end
    end
  end

  shared_examples 'secure mailing replying' do
    context 'when replying', authenticated_as: :setup_and_authenticate do

      def setup_and_authenticate
        create(:ticket_article, ticket: ticket, from: customer.email)

        create(secure_mailing_factory_name, :with_private, fixture: system_email_address)
        create(secure_mailing_factory_name, fixture: sender_email_address)

        authenticate
      end

      it 'plain' do
        visit "#ticket/zoom/#{ticket.id}"

        all('a[data-type=emailReply]').last.click
        find('.articleNewEdit-body').send_keys('Test')

        expect(page).to have_css('.js-securityEncrypt.btn--active')
          .and(have_css('.js-securitySign.btn--active'))

        click '.js-securityEncrypt'
        click '.js-securitySign'

        click '.js-submit'
        expect(page).to have_css('.ticket-article-item', count: 2)

        expect(Ticket::Article.last.preferences['security']['encryption']['success']).to be_nil
        expect(Ticket::Article.last.preferences['security']['sign']['success']).to be_nil
      end

      it 'signed' do
        visit "#ticket/zoom/#{ticket.id}"

        all('a[data-type=emailReply]').last.click
        find('.articleNewEdit-body').send_keys('Test')

        expect(page).to have_css('.js-securityEncrypt.btn--active')
        expect(page).to have_css('.js-securitySign.btn--active')

        click '.js-securityEncrypt'

        click '.js-submit'
        expect(page).to have_css('.ticket-article-item', count: 2)

        expect(Ticket::Article.last.preferences).to include(
          'security' => include(
            'encryption' => be_empty,
            'sign'       => include('success' => be_truthy),
          )
        )
      end

      it 'encrypted' do
        visit "#ticket/zoom/#{ticket.id}"

        all('a[data-type=emailReply]').last.click
        find('.articleNewEdit-body').send_keys('Test')

        expect(page).to have_css('.js-securityEncrypt.btn--active')
        expect(page).to have_css('.js-securitySign.btn--active')

        click '.js-securitySign'

        click '.js-submit'
        expect(page).to have_css('.ticket-article-item', count: 2)

        expect(Ticket::Article.last.preferences).to include(
          'security' => include(
            'encryption' => include('success' => be_truthy),
            'sign'       => be_empty,
          )
        )
      end

      it 'signed and encrypted' do
        visit "#ticket/zoom/#{ticket.id}"

        all('a[data-type=emailReply]').last.click
        find('.articleNewEdit-body').send_keys('Test')

        expect(page).to have_css('.js-securityEncrypt.btn--active')
        expect(page).to have_css('.js-securitySign.btn--active')

        click '.js-submit'
        expect(page).to have_css('.ticket-article-item', count: 2)

        expect(Ticket::Article.last.preferences).to include(
          'security' => include(
            'encryption' => include('success' => be_truthy),
            'sign'       => include('success' => be_truthy),
          )
        )
      end
    end
  end

  shared_examples 'secure mailing group behavior' do
    describe 'Group default behavior', authenticated_as: :setup_and_authenticate do

      let(:secure_mailing_config) { {} }

      def setup_and_authenticate
        Setting.set(secure_mailing_config_name, secure_mailing_config)

        create(:ticket_article, ticket: ticket, from: customer.email)

        create(secure_mailing_factory_name, :with_private, fixture: system_email_address)
        create(secure_mailing_factory_name, fixture: sender_email_address)

        authenticate
      end

      shared_examples 'security defaults example' do |sign:, encrypt:|

        it "security defaults sign: #{sign}, encrypt: #{encrypt}" do
          within(:active_content) do
            if sign
              expect(page).to have_css('.js-securitySign.btn--active')
            else
              expect(page).to have_no_css('.js-securitySign.btn--active')
            end
            if encrypt
              expect(page).to have_css('.js-securityEncrypt.btn--active')
            else
              expect(page).to have_no_css('.js-securityEncrypt.btn--active')
            end
          end
        end
      end

      shared_examples 'security defaults' do |sign:, encrypt:|

        before do
          visit "#ticket/zoom/#{ticket.id}"

          within(:active_content) do
            all('a[data-type=emailReply]').last.click
            find('.articleNewEdit-body').send_keys('Test')
          end
        end

        include_examples 'security defaults example', sign: sign, encrypt: encrypt
      end

      shared_examples 'security defaults group change' do |sign:, encrypt:|

        before do
          visit "#ticket/zoom/#{ticket.id}"

          within(:active_content) do
            all('a[data-type=emailReply]').last.click
            find('.articleNewEdit-body').send_keys('Test')

            set_tree_select_value('group_id', new_group.name)
          end
        end

        include_examples 'security defaults example', sign: sign, encrypt: encrypt
      end

      context 'when not configured' do
        it_behaves_like 'security defaults', sign: true, encrypt: true
      end

      context 'when configuration present' do

        let(:secure_mailing_config) do
          {
            'group_id' => group_defaults
          }
        end

        let(:group_defaults) do
          {
            'default_encryption' => {
              group.id.to_s => default_encryption,
            },
            'default_sign'       => {
              group.id.to_s => default_sign,
            }
          }
        end

        let(:default_sign)       { true }
        let(:default_encryption) { true }

        shared_examples 'sign and encrypt variations' do |check_examples_name|

          it_behaves_like check_examples_name, sign: true, encrypt: true

          context 'when no value present' do
            let(:group_defaults) { {} }

            it_behaves_like check_examples_name, sign: true, encrypt: true
          end

          context 'when signing is disabled' do
            let(:default_sign) { false }

            it_behaves_like check_examples_name, sign: false, encrypt: true
          end

          context 'when encryption is disabled' do
            let(:default_encryption) { false }

            it_behaves_like check_examples_name, sign: true, encrypt: false
          end
        end

        context 'when same Group' do
          it_behaves_like 'sign and encrypt variations', 'security defaults'
        end

        context 'when Group change' do
          let(:new_group) { create(:group, email_address: email_address) }

          let(:agent_groups) { [group, new_group] }

          let(:group_defaults) do
            {
              'default_encryption' => {
                new_group.id.to_s => default_encryption,
              },
              'default_sign'       => {
                new_group.id.to_s => default_sign,
              }
            }
          end

          it_behaves_like 'sign and encrypt variations', 'security defaults group change'
        end
      end
    end
  end

  describe 'S/MIME active', authenticated_as: :authenticate do
    let(:system_email_address) { 'smime1@example.com' }
    let(:email_address)        { create(:email_address, email: system_email_address) }
    let(:group)                { create(:group, email_address: email_address) }
    let(:agent_groups)         { [group] }
    let(:agent)                { create(:agent, groups: agent_groups) }

    let(:secure_mailing_factory_name) { :smime_certificate }
    let(:secure_mailing_config_name)               { :smime_config }
    let(:secure_mailing_type_name)                 { 'S/MIME' }
    let(:secure_mailing_decryption_failed_message) { 'Decryption failed! The private key for decryption could not be found.' }

    let(:sender_email_address) { 'smime2@example.com' }
    let(:customer) { create(:customer, email: sender_email_address) }

    let(:ticket) { create(:ticket, group: group, owner: agent, customer: customer) }

    def authenticate
      Setting.set('smime_integration', true)
      agent
    end

    include_examples 'secure mailing received mail'
    include_examples 'secure mailing replying'
    include_examples 'secure mailing group behavior'
  end

  describe 'PGP active', authenticated_as: :authenticate do
    let(:system_email_address) { 'pgp1@example.com' }
    let(:email_address)        { create(:email_address, email: system_email_address) }
    let(:group)                { create(:group, email_address: email_address) }
    let(:agent_groups)         { [group] }
    let(:agent)                { create(:agent, groups: agent_groups) }

    let(:secure_mailing_factory_name) { :pgp_key }
    let(:secure_mailing_config_name)               { :pgp_config }
    let(:secure_mailing_type_name)                 { 'PGP' }
    let(:secure_mailing_decryption_failed_message) { 'Decryption failed! The private PGP key could not be found.' }

    let(:sender_email_address) { 'pgp2@example.com' }
    let(:customer) { create(:customer, email: sender_email_address) }

    let(:ticket) { create(:ticket, group: group, owner: agent, customer: customer) }

    def authenticate
      Setting.set('pgp_integration', true)
      agent
    end

    include_examples 'secure mailing received mail'
    include_examples 'secure mailing replying'
    include_examples 'secure mailing group behavior'
  end

  context 'with both PGP and S/MIME integration', authenticated_as: :authenticate do
    def authenticate
      Setting.set('pgp_integration', true)
      Setting.set('smime_integration', true)

      agent
    end

    let(:system_email_address)    { 'pgp+smime-sender@example.com' }
    let(:recipient_email_address) { 'pgp+smime-recipient@example.com' }

    let(:email_address) { create(:email_address, email: system_email_address) }
    let(:group)         { create(:group, email_address: email_address) }
    let(:agent)         { create(:agent, groups: [group]) }
    let(:customer)      { create(:customer, email: recipient_email_address) }
    let(:ticket)        { create(:ticket, group: group, owner: agent, customer: customer) }

    shared_examples 'showing security type switcher' do
      it 'shows security type switcher' do
        visit "#ticket/zoom/#{ticket.id}"

        within(:active_content) do
          all('a[data-type=emailReply]').last.click

          expect(page).to have_css('.btn', text: 'PGP')
            .and(have_css('.btn.btn--active', text: 'S/MIME')) # preferred
        end
      end
    end

    context 'with no certificates nor keys present' do
      before do
        create(:ticket_article, ticket: ticket, from: customer.email)
      end

      it_behaves_like 'showing security type switcher'
    end

    context 'with certificates and keys present' do
      before do
        create(:ticket_article, ticket: ticket, from: customer.email)

        create(:pgp_key, :with_private, fixture: system_email_address)
        create(:pgp_key, fixture: recipient_email_address)
        create(:smime_certificate, :with_private, fixture: system_email_address)
        create(:smime_certificate, fixture: recipient_email_address)
      end

      it_behaves_like 'showing security type switcher'

      it 'switches between security types' do
        visit "#ticket/zoom/#{ticket.id}"

        within(:active_content) do
          all('a[data-type=emailReply]').last.click

          # Wait until the security options check AJAX call is ready.
          expect(page).to have_css('div.js-securityEncrypt.btn--active')
            .and(have_css('div.js-securitySign.btn--active'))

          expect(page).to have_css('.btn', text: 'PGP')
            .and(have_css('.btn.btn--active', text: 'S/MIME')) # preferred

          expect(find('.js-securityEncryptComment')['title']).to eq('The certificates for pgp+smime-recipient@example.com were found.')
          expect(find('.js-securitySignComment')['title']).to eq('The certificate for pgp+smime-sender@example.com was found.')

          click '.btn', text: 'PGP'

          # Wait until the security options check AJAX call is ready.
          expect(page).to have_css('div.js-securityEncrypt.btn--active')
            .and(have_css('div.js-securitySign.btn--active'))

          expect(page).to have_no_css('.btn.btn--active', text: 'S/MIME')
            .and(have_css('.btn.btn--active', text: 'PGP'))

          expect(find('.js-securityEncryptComment')['title']).to eq('The PGP keys for pgp+smime-recipient@example.com were found.')
          expect(find('.js-securitySignComment')['title']).to eq('The PGP key for pgp+smime-sender@example.com was found.')
        end
      end
    end
  end
end
