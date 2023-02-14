# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
RSpec.describe 'Clearbit', aggregate_failures: true, current_user_id: 1, integration: true, performs_jobs: true, required_envs: %w[CLEARBIT_CI_API_KEY] do
  let(:clearbit_config_organization_shared) { false }
  let(:clearbit_config_user_bio)            { 'user.note' }
  let(:clearbit_config_company_bio)         { 'organization.note' }
  let(:clearbit_config_user_familyname)     { 'user.lastname' }

  before do
    Setting.set('clearbit_integration', true)
    Setting.set('clearbit_config', {
                  api_key:                 ENV['CLEARBIT_CI_API_KEY'],
                  organization_autocreate: true,
                  organization_shared:     clearbit_config_organization_shared,
                  user_sync:               {
                    'person.name.givenName'  => 'user.firstname',
                    'person.name.familyName' => clearbit_config_user_familyname,
                    'person.email'           => 'user.email',
                    'person.bio'             => clearbit_config_user_bio,
                    'company.url'            => 'user.web',
                    'person.site'            => 'user.web',
                    'company.location'       => 'user.address',
                    'person.location'        => 'user.address',
                  },
                  organization_sync:       {
                    'company.legalName'   => 'organization.name',
                    'company.name'        => 'organization.name',
                    'company.description' => clearbit_config_company_bio,
                  },
                })
  end

  describe 'case 1 - person + company (demo data set)' do
    let(:customer) do
      User.create!(
        firstname: '',
        lastname:  'Should be still there',
        email:     'alex@alexmaccaw.com',
        note:      '',
      )
    end

    before do
      customer

      perform_enqueued_jobs commit_transaction: true

      customer.reload
    end

    it 'enriches the customer' do
      expect(ExternalSync).to be_exist(source: 'clearbit', object: 'User', o_id: customer.id)

      expect(customer).to have_attributes(
        firstname: 'Should',
        lastname:  'be still there',
        note:      'O\'Reilly author, software engineer &amp; traveller. Founder of <a href="https://clearbit.com" rel="nofollow noreferrer noopener" target="_blank">https://clearbit.com</a>',
        address:   '1455 Market Street, San Francisco, CA 94103, USA',
      )
    end

    it 'creates organization with enriched data' do
      expect(ExternalSync).to be_exist(source: 'clearbit', object: 'Organization', o_id: customer.organization.id)

      expect(customer.organization).to have_attributes(
        name:   'Uber, Inc.',
        shared: false,
        note:   'Uber is a mobile app connecting passengers with drivers for hire.'
      )
    end

    context 'with organization shared set to true' do
      let(:clearbit_config_organization_shared) { true }

      it 'creates organization with enriched data' do
        expect(customer.organization).to have_attributes(
          name:   'Uber, Inc.',
          shared: true,
        )
      end
    end

    context 'with non existing note field' do
      let(:clearbit_config_user_bio)    { 'user.note_not_existing' }
      let(:clearbit_config_company_bio) { 'organization.note_not_existing' }

      it 'syncs the rest of user fields' do
        expect(ExternalSync).to be_exist(source: 'clearbit', object: 'User', o_id: customer.id)

        expect(customer).to have_attributes(
          firstname: 'Should',
          lastname:  'be still there',
          note:      '',
        )
      end

      it 'syncs the rest of organization fields' do
        expect(ExternalSync).to be_exist(source: 'clearbit', object: 'Organization', o_id: customer.organization.id)

        expect(customer.organization).to have_attributes(
          name: 'Uber, Inc.',
          note: ''
        )
      end
    end
  end

  describe 'case 2 - person + company' do
    let(:customer) do
      User.create!(
        firstname: '',
        lastname:  '',
        email:     'me@example.com',
        note:      '',
      )
    end

    before do
      customer

      perform_enqueued_jobs commit_transaction: true

      customer.reload
    end

    it 'enriches the customer' do
      expect(ExternalSync).to be_exist(source: 'clearbit', object: 'User', o_id: customer.id)

      expect(customer).to have_attributes(
        firstname: 'Martin',
        lastname:  'Edenhofer',
        note:      "Open Source professional and geek. Also known as OTRS inventor. ;)\r\nEntrepreneur and Advisor for open source people in need.",
        address:   'Norsk-Data-Straße 1, 61352 Bad Homburg vor der Höhe, Germany',
      )
    end

    it 'creates organization with enriched data' do
      expect(ExternalSync).to be_exist(source: 'clearbit', object: 'Organization', o_id: customer.organization.id)

      expect(customer.organization).to have_attributes(
        name: 'OTRS',
        note: 'OTRS is an Open Source helpdesk software and an IT Service Management software free of licence costs. Improve your Customer Service Management with OTRS.'
      )
    end

    context 'when email changes' do
      before do
        customer.update!(
          email: 'me2@example.com',
        )

        Enrichment::Clearbit::User.new(customer).synced?

        perform_enqueued_jobs commit_transaction: true
      end

      it 'Update with another email data' do
        expect(customer.reload).to have_attributes(
          firstname: 'Martini',
          lastname:  'Edenhofer',
          address:   'Norsk-Data-Straße 1, 61352 Bad Homburg vor der Höhe, Germany',
        )
      end
    end

    context 'when updated locally' do
      before do
        customer.update!(
          firstname: 'Martini',
          note:      'changed by my self',
        )

        Enrichment::Clearbit::User.new(customer).synced?

        perform_enqueued_jobs commit_transaction: true
      end

      it 'stores locally updated value' do
        expect(customer.reload).to have_attributes(
          firstname: 'Martini',
          lastname:  'Edenhofer',
          note:      'changed by my self',
          address:   'Norsk-Data-Straße 1, 61352 Bad Homburg vor der Höhe, Germany',
        )
      end

      context 'when set to empty value' do
        before do
          customer.update!(
            firstname: '',
            note:      'changed by my self again',
          )

          Enrichment::Clearbit::User.new(customer).synced?

          perform_enqueued_jobs commit_transaction: true
        end

        it 'reverts to enriched data' do
          expect(customer.reload).to have_attributes(
            firstname: 'Martin',
            lastname:  'Edenhofer',
            note:      'changed by my self again',
            address:   'Norsk-Data-Straße 1, 61352 Bad Homburg vor der Höhe, Germany',
          )
        end
      end
    end
  end

  describe 'case 3 - no person' do
    let(:customer) do
      User.create!(
        firstname: '',
        lastname:  '',
        email:     'testing3@znuny.com',
        note:      '',
      )
    end

    before do
      customer

      perform_enqueued_jobs commit_transaction: true

      customer.reload
    end

    it 'does not enrich the customer' do
      expect(ExternalSync).not_to be_exist(source: 'clearbit', object: 'User', o_id: customer.id)

      expect(customer.reload).to have_attributes(
        firstname: '',
        lastname:  '',
        note:      '',
        web:       'http://znuny.com',
        address:   'Marienstraße 11, 10117 Berlin, Germany',
      )
    end

    it 'creates organization with enriched data' do
      expect(ExternalSync).to be_exist(source: 'clearbit', object: 'Organization', o_id: customer.organization.id)

      expect(customer.organization).to have_attributes(
        name: 'Znuny / ES for OTRS',
        note: 'OTRS Support, Consulting, Development, Training and Customizing - Znuny GmbH'
      )
    end
  end

  describe 'case 4 - person with organization but organization is already assigned (own created)' do
    let(:customer) do
      User.create!(
        firstname:       '',
        lastname:        '',
        email:           'testing4@znuny.com',
        note:            '',
        organization_id: 1,
      )
    end

    before do
      customer

      perform_enqueued_jobs commit_transaction: true

      customer.reload
    end

    it 'enriches the customer' do
      expect(customer).to have_attributes(
        firstname: 'Fred',
        lastname:  'Jupiter',
        note:      'some_fred_bio',
        web:       'http://fred.znuny.com',
        address:   'Marienstraße 11, 10117 Berlin, Germany',
      )
    end

    it 'does not create organization with enriched data' do
      expect(customer.organization).to be_present

      expect(Organization).not_to be_exist(name: 'ZnunyOfFred')
    end
  end

  describe 'case 5 - person with organization but organization is already assigned (own created)' do
    let(:customer) do
      User.create!(
        firstname:       '',
        lastname:        '',
        email:           'testing5@znuny.com',
        note:            '',
        created_by_id:   1,
        updated_by_id:   1,
        organization_id: another_clearbit_organization.id,
      )
    end

    let(:another_clearbit_organization) do
      user = User.create!(email: 'testing3@znuny.com')

      perform_enqueued_jobs commit_transaction: true

      user.reload.organization
    end

    before do
      customer

      perform_enqueued_jobs commit_transaction: true

      customer.reload
    end

    it 'enriches the customer' do
      expect(ExternalSync).to be_exist(source: 'clearbit', object: 'User', o_id: customer.id)

      expect(customer).to have_attributes(
        firstname: 'Alex',
        lastname:  'Dont',
        note:      'some_bio_alex',
        web:       'http://znuny.com',
        address:   'Marienstraße 11, 10117 Berlin, Germany',
      )
    end

    it 'updates existing organization with enriched data' do
      expect(customer.organization).to have_attributes(
        name: 'Znuny GmbH',
        note: 'OTRS Support, Consulting, Development, Training and Customizing - Znuny GmbH'
      )

      expect(another_clearbit_organization.id).to eq customer.organization.id
    end
  end

  describe 'case 6 - no person / real api call' do
    let(:customer) do
      User.create!(
        firstname: '',
        lastname:  '',
        email:     'testing6@clearbit.com',
        note:      '',
      )
    end

    before do
      customer

      VCR.configure do |c|
        c.ignore_hosts 'person-stream.clearbit.com'
      end

      perform_enqueued_jobs commit_transaction: true

      VCR.configure do |c|
        c.unignore_hosts 'person-stream.clearbit.com'
      end

      customer.reload
    end

    it 'does not enrich the customer' do
      expect(ExternalSync).not_to be_exist(source: 'clearbit', object: 'User', o_id: customer.id)

      expect(customer).to have_attributes(
        firstname: '',
        lastname:  '',
        note:      '',
        web:       '',
        address:   be_in(
          [
            'San Francisco, CA, USA',
            'San Francisco, CA 94103, USA',
            '90 Sheridan St, San Francisco, CA 94103, USA',
            '90 Sheridan, San Francisco, CA 94103, USA',
            '3030 16th St, San Francisco, CA 94103, USA',
            '548 Market St, San Francisco, CA 94104, USA',
          ]
        )
      )
    end

    it 'creates organization with enriched data' do
      expect(ExternalSync).to be_exist(source: 'clearbit', object: 'Organization', o_id: customer.organization.id)

      expect(customer.organization).to have_attributes(
        name: start_with('APIHub Inc'),
        note: 'The Clearbit Data Activation Platform helps B2B teams understand customers, identify prospects, &amp; personalize interactions with real-time intelligence.'
      )
    end
  end

  context 'when using custom attribute', db_strategy: :reset do
    let(:clearbit_config_user_familyname) { 'user.test_input' }

    let(:customer) do
      User.create!(
        firstname: '',
        lastname:  '',
        email:     'testing6@znuny.com',
        note:      '',
      )
    end

    before do
      create(:object_manager_attribute_text, object_name: 'User', name: 'test_input', data_option_maxlength: 2)
      ObjectManager::Attribute.migration_execute

      customer

      perform_enqueued_jobs commit_transaction: true

      customer.reload
    end

    it 'Limits enrichment data to database limit' do
      expect(ExternalSync).to be_exist(source: 'clearbit', object: 'User', o_id: customer.id)

      expect(customer.test_input).to eq 'Sm'
    end
  end
end
