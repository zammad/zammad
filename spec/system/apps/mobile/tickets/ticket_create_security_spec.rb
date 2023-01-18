# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/apps/mobile/examples/core_workflow_examples'

RSpec.describe 'Mobile > Ticket > Create with security options', app: :mobile, authenticated_as: :authenticate, type: :system do
  let(:group)     { Group.find_by(name: 'Users') }
  let(:agent)     { create(:agent, groups: [group]) }
  let!(:customer) { create(:customer) }

  def authenticate
    Setting.set('smime_integration', true)
    Setting.set('smime_config', smime_config) if defined?(smime_config)

    agent
  end

  def prepare_phone_ticket
    within_form(form_updater_gql_number: 1) do
      # Step 1.
      find_input('Title').type(Faker::Name.name_with_middle)
      next_step

      # Step 2.
      next_step

      # Step 3.
      find_autocomplete('Customer').search_for_option(customer.email, label: customer.fullname)
      next_step
    end
  end

  def prepare_email_ticket(with_body: false)
    within_form(form_updater_gql_number: 1) do
      # Step 1.
      find_input('Title').type(Faker::Name.name_with_middle)
      next_step

      # Step 2.
      find_radio('articleSenderType').select_choice('Send Email')
      next_step

      # Step 3.
      find_autocomplete('Customer').search_for_option(customer.email, label: customer.fullname)
      next_step

      # Step 4.
      if with_body
        find_editor('Text').type(Faker::Hacker.say_something_smart)
      end
    end
  end

  def next_step
    find_button('Continue').click
  end

  def go_to_step(step)
    find("button[order=\"#{step}\"]").click
  end

  def submit_form
    find_button('Create ticket', match: :first).click
    wait_for_gql('apps/mobile/pages/ticket/graphql/mutations/create.graphql')
  end

  before do
    visit '/tickets/create'
    wait_for_form_to_settle('ticket-create')
  end

  shared_examples 'having available security options' do |encrypt:, sign:|
    it "available security options - encrypt: #{encrypt}, sign: #{sign}" do
      prepare_email_ticket

      expect { find_outer('Security') }.not_to raise_error
      expect(find_button('Encrypt', disabled: !encrypt).disabled?).to be(!encrypt)
      expect(find_button('Sign', disabled: !sign).disabled?).to be(!sign)
    end
  end

  shared_examples 'creating a ticket' do |encrypt:, sign:|
    it "can create a ticket - encrypt: #{encrypt}, sign: #{sign}" do
      prepare_email_ticket with_body: true
      submit_form

      find('[role=alert]', text: 'Ticket has been created successfully.')

      expect(Ticket.last.articles.last.preferences['security']['encryption']['success']).to be(encrypt)
      expect(Ticket.last.articles.last.preferences['security']['sign']['success']).to be(sign)
    end
  end

  context 'without certificates present' do
    it_behaves_like 'having available security options', encrypt: false, sign: false
    it_behaves_like 'creating a ticket', encrypt: false, sign: false
  end

  context 'with sender certificate present' do
    let(:system_email_address) { 'smime1@example.com' }
    let(:email_address)        { create(:email_address, email: system_email_address) }
    let(:group)                { create(:group, email_address: email_address) }

    before do
      create(:smime_certificate, :with_private, fixture: system_email_address)
    end

    it_behaves_like 'having available security options', encrypt: false, sign: true
    it_behaves_like 'creating a ticket', encrypt: false, sign: true

    context 'with recipient certificate present' do
      let(:recipient_email_address) { 'smime2@example.com' }
      let(:customer)                { create(:customer, email: recipient_email_address) }

      before do
        create(:smime_certificate, fixture: recipient_email_address)
      end

      it_behaves_like 'having available security options', encrypt: true, sign: true
      it_behaves_like 'creating a ticket', encrypt: true, sign: true

      it 'hides the security field for phone tickets' do
        prepare_phone_ticket

        expect(page).to have_no_css('label', text: 'Security')
      end

      context 'with default group configuration' do
        let(:smime_config) do
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
            prepare_email_ticket

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
    let(:recipient_email_address) { 'smime2@example.com' }
    let(:customer)                { create(:customer, email: recipient_email_address) }

    before do
      create(:smime_certificate, fixture: recipient_email_address)
    end

    it_behaves_like 'having available security options', encrypt: true, sign: false
    it_behaves_like 'creating a ticket', encrypt: true, sign: false
  end
end
