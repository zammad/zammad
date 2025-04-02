# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket create > Secure mailing', authenticated_as: :authenticate, type: :system do
  def authenticate
    integration_settings
    current_user
  end

  shared_examples 'hiding security options' do
    let!(:template)    { create(:template, :dummy_data) }
    let(:current_user) { true }

    it 'hides security options' do
      visit 'ticket/create'

      within(:active_content) do
        use_template(template)

        expect(page).to have_no_css('div.js-securityEncrypt.btn--active')
        expect(page).to have_no_css('div.js-securitySign.btn--active')
        click '.js-submit'

        expect(page).to have_css('.ticket-article-item', count: 1)

        open_article_meta

        expect(page).to have_no_css('span', text: 'Signed')
        expect(page).to have_no_css('span', text: 'Encrypted')

        security_result = Ticket::Article.last.preferences['security']
        expect(security_result['encryption']['success']).to be_nil
        expect(security_result['sign']['success']).to be_nil
      end
    end
  end

  shared_examples 'supporting all security options' do
    let(:current_user)  { agent }
    let!(:template)     { create(:template, :dummy_data, group: group, owner: agent, customer: customer) }
    let(:email_address) { create(:email_address, email: system_email_address) }
    let(:group)         { create(:group, email_address: email_address) }
    let(:agent_groups)  { [group] }
    let(:agent)         { create(:agent, groups: agent_groups) }
    let(:customer)      { create(:customer, email: recipient_email_address) }

    it 'sends a plain article' do
      visit 'ticket/create'

      within(:active_content) do
        use_template(template)

        # Wait until the security options check AJAX call is ready.
        expect(page).to have_css('div.js-securityEncrypt.btn--active')
        expect(page).to have_css('div.js-securitySign.btn--active')

        # Deactivate encryption and signing.
        click '.js-securityEncrypt'
        click '.js-securitySign'

        click '.js-submit'

        expect(page).to have_css('.ticket-article-item', count: 1)

        open_article_meta

        expect(page).to have_no_css('span', text: 'Signed')
        expect(page).to have_no_css('span', text: 'Encrypted')

        security_result = Ticket::Article.last.preferences['security']
        expect(security_result['encryption']['success']).to be_nil
        expect(security_result['sign']['success']).to be_nil
      end
    end

    it 'sends a signed article' do
      visit 'ticket/create'

      within(:active_content) do
        use_template(template)

        # Wait until the security options check AJAX call is ready.
        expect(page).to have_css('div.js-securityEncrypt.btn--active')
        expect(page).to have_css('div.js-securitySign.btn--active')

        # Deactivate encryption only.
        click '.js-securityEncrypt'

        click '.js-submit'

        expect(page).to have_css('.ticket-article-item', count: 1)

        open_article_meta

        expect(page).to have_css('span', text: 'Signed')
        expect(page).to have_no_css('span', text: 'Encrypted')

        security_result = Ticket::Article.last.preferences['security']
        expect(security_result['encryption']['success']).to be_nil
        expect(security_result['sign']['success']).to be true
      end
    end

    it 'sends an encrypted article' do
      visit 'ticket/create'

      within(:active_content) do
        use_template(template)

        # Wait until the security options check AJAX call is ready.
        expect(page).to have_css('div.js-securityEncrypt.btn--active')
        expect(page).to have_css('div.js-securitySign.btn--active')

        # Deactivate signing only.
        click '.js-securitySign'

        click '.js-submit'

        expect(page).to have_css('.ticket-article-item', count: 1)

        open_article_meta

        expect(page).to have_no_css('span', text: 'Signed')
        expect(page).to have_css('span', text: 'Encrypted')

        security_result = Ticket::Article.last.preferences['security']
        expect(security_result['encryption']['success']).to be true
        expect(security_result['sign']['success']).to be_nil
      end
    end

    it 'sends a signed and encrypted article' do
      visit 'ticket/create'

      within(:active_content) do
        use_template(template)

        # Wait until the security options check AJAX call is ready.
        expect(page).to have_css('div.js-securityEncrypt.btn--active')
        expect(page).to have_css('div.js-securitySign.btn--active')

        click '.js-submit'

        expect(page).to have_css('.ticket-article-item', count: 1)

        open_article_meta

        expect(page).to have_css('span', text: 'Signed')
        expect(page).to have_css('span', text: 'Encrypted')

        security_result = Ticket::Article.last.preferences['security']
        expect(security_result['encryption']['success']).to be true
        expect(security_result['sign']['success']).to be true
      end
    end
  end

  shared_examples 'supporting group default behavior' do
    let(:current_user)       { agent }
    let!(:template)          { create(:template, :dummy_data, group: group, owner: agent, customer: customer) }
    let(:email_address)      { create(:email_address, email: system_email_address) }
    let(:group)              { create(:group, email_address: email_address) }
    let(:agent_groups)       { [group] }
    let(:agent)              { create(:agent, groups: agent_groups) }
    let(:customer)           { create(:customer, email: recipient_email_address) }
    let(:integration_config) { {} }

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
        visit 'ticket/create'

        within(:active_content) do
          use_template(template)
        end
      end

      include_examples 'security defaults example', sign: sign, encrypt: encrypt
    end

    shared_examples 'security defaults group change' do |sign:, encrypt:|
      before do
        visit 'ticket/create'

        within(:active_content) do
          use_template(template)

          set_tree_select_value('group_id', new_group.name)
        end
      end

      include_examples 'security defaults example', sign: sign, encrypt: encrypt
    end

    context 'when not configured' do
      it_behaves_like 'security defaults', sign: true, encrypt: true
    end

    context 'when configuration is present' do
      let(:integration_config) do
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

      context 'with the same group' do
        it_behaves_like 'sign and encrypt variations', 'security defaults'
      end

      context 'with a group change' do
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

  context 'with PGP integration' do
    let(:integration_settings) do
      Setting.set('pgp_integration', true)
      Setting.set('pgp_config', integration_config) if defined?(integration_config)
    end

    context 'with no key present' do
      it_behaves_like 'hiding security options'
    end

    context 'with recipient public key and sender private key present' do
      let(:system_email_address)    { 'pgp1@example.com' }
      let(:recipient_email_address) { 'pgp2@example.com' }

      before do
        create(:'pgp_key/pgp1@example.com', :with_private)
        create(:'pgp_key/pgp2@example.com')
      end

      it_behaves_like 'supporting all security options'
      it_behaves_like 'supporting group default behavior'
    end
  end

  context 'with S/MIME integration' do
    let(:integration_settings) do
      Setting.set('smime_integration', true)
      Setting.set('smime_config', integration_config) if defined?(integration_config)
    end

    context 'with no certificate nor key present' do
      it_behaves_like 'hiding security options'
    end

    context 'with recipient public certificate and sender private key present' do
      let(:system_email_address)    { 'smime1@example.com' }
      let(:recipient_email_address) { 'smime2@example.com' }

      before do
        create(:smime_certificate, :with_private, fixture: system_email_address)
        create(:smime_certificate, fixture: recipient_email_address)
      end

      it_behaves_like 'supporting all security options'
      it_behaves_like 'supporting group default behavior'
    end
  end

  context 'with both PGP and S/MIME integration' do
    let(:integration_settings) do
      Setting.set('pgp_integration', true)
      Setting.set('smime_integration', true)
    end

    shared_examples 'showing security type switcher' do
      let!(:template)    { create(:template, :dummy_data) }
      let(:current_user) { true }

      it 'shows security type switcher' do
        visit 'ticket/create'

        within(:active_content) do
          use_template(template)

          expect(page).to have_css('.btn', text: 'PGP')
          expect(page).to have_css('.btn.btn--active', text: 'S/MIME') # preferred
        end
      end
    end

    context 'with no certificates nor keys present' do
      it_behaves_like 'showing security type switcher'
    end

    context 'with certificates and keys present' do
      let(:system_email_address)    { 'pgp+smime-sender@example.com' }
      let(:recipient_email_address) { 'pgp+smime-recipient@example.com' }
      let(:current_user)            { agent }
      let!(:template)               { create(:template, :dummy_data, group: group, owner: agent, customer: customer) }
      let(:email_address)           { create(:email_address, email: system_email_address) }
      let(:group)                   { create(:group, email_address: email_address) }
      let(:agent_groups)            { [group] }
      let(:agent)                   { create(:agent, groups: agent_groups) }
      let(:customer)                { create(:customer, email: recipient_email_address) }

      before do
        create(:'pgp_key/pgp+smime-sender@example.com', :with_private)
        create(:'pgp_key/pgp+smime-recipient@example.com')
        create(:smime_certificate, :with_private, fixture: system_email_address)
        create(:smime_certificate, fixture: recipient_email_address)
      end

      shared_examples 'switching between security types' do
        it 'switches between security types' do
          within(:active_content) do

            click '.btn', text: 'PGP'

            # Wait until the security options check AJAX call is ready.
            expect(page).to have_css('div.js-securityEncrypt.btn--active')
            expect(page).to have_css('div.js-securitySign.btn--active')

            expect(page).to have_css('.btn.btn--active', text: 'PGP')
            expect(page).to have_no_css('.btn.btn--active', text: 'S/MIME')

            expect(find('.js-securityEncryptComment')['title']).to eq('The PGP keys for pgp+smime-recipient@example.com were found.')
            expect(find('.js-securitySignComment')['title']).to eq('The PGP key for pgp+smime-sender@example.com was found.')

            click '.btn', text: 'S/MIME'

            # Wait until the security options check AJAX call is ready.
            expect(page).to have_css('div.js-securityEncrypt.btn--active')
            expect(page).to have_css('div.js-securitySign.btn--active')

            expect(page).to have_no_css('.btn.btn--active', text: 'PGP')
            expect(page).to have_css('.btn.btn--active', text: 'S/MIME')

            expect(find('.js-securityEncryptComment')['title']).to eq('The certificates for pgp+smime-recipient@example.com were found.')
            expect(find('.js-securitySignComment')['title']).to eq('The certificate for pgp+smime-sender@example.com was found.')
          end
        end
      end

      it_behaves_like 'showing security type switcher'

      context 'when customer selection is based on template' do
        before do
          visit 'ticket/create'

          within(:active_content) do
            use_template(template)
          end
        end

        it_behaves_like 'switching between security types'
      end

      context 'when customer selection is based on manual selection' do
        before do
          visit 'ticket/create'

          within(:active_content) do
            click '.tab', text: 'Send Email'
            find('[name=customer_id_completion]').fill_in with: customer.firstname
            find("li.recipientList-entry.js-object[data-object-id='#{customer.id}']").click
          end
        end

        it_behaves_like 'switching between security types'
      end
    end
  end
end
