# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/apps/mobile_old/examples/article_security_examples'

RSpec.describe 'Mobile > Ticket > Create with security options', app: :mobile, authenticated_as: :authenticate, type: :system do
  def prepare_phone_article
    within_form(form_updater_gql_number: 1) do
      # Step 1.
      find_input('Title').type(Faker::Name.unique.name_with_middle)
      next_step

      # Step 2.
      next_step

      # Step 3.
      find_autocomplete('Customer').search_for_option(customer.email, label: customer.fullname)
      next_step
    end
  end

  def prepare_email_article(with_body: false)
    within_form(form_updater_gql_number: 1) do
      # Step 1.
      find_input('Title').type(Faker::Name.unique.name_with_middle)
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
    wait_for_gql('shared/entities/ticket/graphql/mutations/create.graphql')
  end

  before do
    visit '/tickets/create'
    wait_for_form_to_settle('ticket-create')
  end

  context 'when setting security options' do
    let(:group)         { Group.find_by(name: 'Users') }
    let(:agent)         { create(:agent, groups: [group]) }
    let!(:customer)     { create(:customer) } # rubocop:disable RSpec/LetSetup

    it_behaves_like 'mobile app: article security', ticket_create: true, integration: :smime
    it_behaves_like 'mobile app: article security', ticket_create: true, integration: :pgp

    context 'when two integrations are enabled', authenticated_as: :agent do
      let(:system_email_address)      { 'pgp+smime-sender@example.com' }
      let(:recipient_email_address)   { 'pgp+smime-recipient@example.com' }
      let(:email_address)             { create(:email_address, email: system_email_address) }
      let(:group)                     { create(:group, email_address: email_address) }
      let!(:customer)                 { create(:customer, email: recipient_email_address) } # rubocop:disable RSpec/LetSetup

      before do
        Setting.set('pgp_integration', true)
        Setting.set('smime_integration', true)

        create(:pgp_key, :with_private, fixture: system_email_address)
        create(:pgp_key, fixture: recipient_email_address)
        create(:smime_certificate, :with_private, fixture: system_email_address)
        create(:smime_certificate, fixture: recipient_email_address)
      end

      it 'can switch between two integrations' do
        prepare_email_article

        expect(page).to have_button('PGP')
        expect(page).to have_button('S/MIME')

        # S/MIME is preferred type when both PGP + S/MIME are configured.
        expect(find_button('S/MIME')['aria-selected']).to eq('true')

        expect(find_button('Encrypt')['aria-selected']).to eq('true')
        expect(find_button('Sign')['aria-selected']).to eq('true')

        click_on('PGP')

        expect(find_button('Encrypt')['aria-selected']).to eq('true')
        expect(find_button('Sign')['aria-selected']).to eq('true')

        click_on('S/MIME')

        expect(find_button('Encrypt')['aria-selected']).to eq('true')
        expect(find_button('Sign')['aria-selected']).to eq('true')
      end
    end
  end
end
