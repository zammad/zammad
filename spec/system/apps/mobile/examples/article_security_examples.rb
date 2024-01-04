# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'mobile app: article security' do |integration:, ticket_create: false|
  let(:security_name) { integration == :pgp ? 'pgp' : 'smime' }
  let(:certificate)   { integration == :pgp ? :pgp_key : :smime_certificate }

  def authenticate
    Setting.set("#{security_name}_integration", true)
    Setting.set("#{security_name}_config", security_config) if defined?(security_config)

    agent
  end

  shared_examples 'having available security options' do |encrypt:, sign:|
    it "available security options - encrypt: #{encrypt}, sign: #{sign}" do
      prepare_email_article

      expect { find_outer('Security') }.not_to raise_error
      expect(find_button('Encrypt', disabled: !encrypt).disabled?).to be(!encrypt)
      expect(find_button('Sign', disabled: !sign).disabled?).to be(!sign)

      click('button[aria-describedby="tooltip-security-security"]')
      expect(page).to have_css('[aria-label="Security Information"]')
    end
  end

  shared_examples 'saving article' do |encrypt:, sign:|
    it "can create a ticket - encrypt: #{encrypt}, sign: #{sign}" do
      prepare_email_article with_body: true
      submit_form

      find('[role=alert]', text: 'Ticket has been created successfully.') if ticket_create

      expect(Ticket.last.articles.last.preferences['security']['encryption']['success']).to be(encrypt)
      expect(Ticket.last.articles.last.preferences['security']['sign']['success']).to be(sign)
    end
  end

  context 'without certificates present' do
    it_behaves_like 'having available security options', encrypt: false, sign: false
    it_behaves_like 'saving article', encrypt: false, sign: false
  end

  context 'with sender certificate present' do
    let(:system_email_address) { "#{security_name}1@example.com" }
    let(:email_address)        { create(:email_address, email: system_email_address) }
    let(:group)                { create(:group, email_address: email_address) }

    before do
      create(certificate, :with_private, fixture: system_email_address)
    end

    it_behaves_like 'having available security options', encrypt: false, sign: true
    it_behaves_like 'saving article', encrypt: false, sign: true

    context 'with recipient certificate present' do
      let(:recipient_email_address) { "#{security_name}2@example.com" }
      let(:customer)                { create(:customer, email: recipient_email_address) }

      before do
        create(certificate, fixture: recipient_email_address)
      end

      it_behaves_like 'having available security options', encrypt: true, sign: true
      it_behaves_like 'saving article', encrypt: true, sign: true

      it 'hides the security field for phone tickets' do
        prepare_phone_article

        expect(page).to have_no_css('label', text: 'Security')
      end

      context 'with default group configuration' do
        let(:security_config) do
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

        shared_examples 'having default security options' do |encrypt:, sign:|
          it "default security options - encrypt: #{encrypt}, sign: #{sign}" do
            prepare_email_article

            expect(find_button('Encrypt')['aria-selected']).to eq(encrypt.to_s)
            expect(find_button('Sign')['aria-selected']).to eq(sign.to_s)
          end
        end

        it_behaves_like 'having default security options', encrypt: true, sign: true

        context 'when it has no value' do
          let(:group_defaults) { {} }

          it_behaves_like 'having default security options', encrypt: true, sign: true
        end

        context 'when signing is disabled' do
          let(:default_sign) { false }

          it_behaves_like 'having default security options', encrypt: true, sign: false
        end

        context 'when encryption is disabled' do
          let(:default_encryption) { false }

          it_behaves_like 'having default security options', encrypt: false, sign: true
        end
      end
    end
  end

  context 'with recipient certificate present' do
    let(:recipient_email_address) { "#{security_name}2@example.com" }
    let(:customer)                { create(:customer, email: recipient_email_address) }

    before do
      create(certificate, fixture: recipient_email_address)
    end

    it_behaves_like 'having available security options', encrypt: true, sign: false
    it_behaves_like 'saving article', encrypt: true, sign: false
  end
end
