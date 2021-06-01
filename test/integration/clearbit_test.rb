# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class ClearbitTest < ActiveSupport::TestCase

  # check
  test 'base' do
    if !ENV['CLEARBIT_CI_API_KEY']
      raise "ERROR: Need CLEARBIT_CI_API_KEY - hint CLEARBIT_CI_API_KEY='abc...'"
    end

    # set system mode to done / to activate
    Setting.set('system_init_done', true)

    Setting.set('clearbit_integration', true)
    Setting.set('clearbit_config', {
                  api_key:                 ENV['CLEARBIT_CI_API_KEY'],
                  organization_autocreate: true,
                  organization_shared:     false,
                  user_sync:               {
                    'person.name.givenName'  => 'user.firstname',
                    'person.name.familyName' => 'user.lastname',
                    'person.email'           => 'user.email',
                    'person.bio'             => 'user.note',
                    'company.url'            => 'user.web',
                    'person.site'            => 'user.web',
                    'company.location'       => 'user.address',
                    'person.location'        => 'user.address',
                    #'person.timeZone' => 'user.preferences[:timezone]',
                    #'person.gender' => 'user.preferences[:gender]',
                  },
                  organization_sync:       {
                    'company.legalName'   => 'organization.name',
                    'company.name'        => 'organization.name',
                    'company.description' => 'organization.note',
                  },
                })

    # case 1 - person + company (demo data set)
    customer1 = User.create!(
      firstname:     '',
      lastname:      'Should be still there',
      email:         'alex@alexmaccaw.com',
      note:          '',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(customer1)

    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert(ExternalSync.find_by(source: 'clearbit', object: 'User', o_id: customer1.id))

    customer1.reload

    assert_equal('Should', customer1.firstname)
    assert_equal('be still there', customer1.lastname)
    assert_equal('O\'Reilly author, software engineer &amp; traveller. Founder of <a href="https://clearbit.com" rel="nofollow noreferrer noopener" target="_blank">https://clearbit.com</a>', customer1.note)
    assert_equal('1455 Market Street, San Francisco, CA 94103, USA', customer1.address)

    organization1 = Organization.find_by(name: 'Uber, Inc.')
    assert(ExternalSync.find_by(source: 'clearbit', object: 'Organization', o_id: organization1.id))
    assert_equal(false, organization1.shared)
    assert_equal('Uber is a mobile app connecting passengers with drivers for hire.', organization1.note)

    # case 2 - person + company
    customer2 = User.create!(
      firstname:     '',
      lastname:      '',
      email:         'me@example.com',
      note:          '',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(customer2)

    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert(ExternalSync.find_by(source: 'clearbit', object: 'User', o_id: customer2.id))

    customer2.reload

    assert_equal('Martin', customer2.firstname)
    assert_equal('Edenhofer', customer2.lastname)
    assert_equal("Open Source professional and geek. Also known as OTRS inventor. ;)\r\nEntrepreneur and Advisor for open source people in need.", customer2.note)
    assert_equal('Norsk-Data-Straße 1, 61352 Bad Homburg vor der Höhe, Germany', customer2.address)

    organization2 = Organization.find_by(name: 'OTRS')
    assert(ExternalSync.find_by(source: 'clearbit', object: 'Organization', o_id: organization2.id))
    assert_equal(false, organization2.shared)
    assert_equal('OTRS is an Open Source helpdesk software and an IT Service Management software free of licence costs. Improve your Customer Service Management with OTRS.', organization2.note)

    # update with own values (do not overwrite)
    customer2.update!(
      firstname: 'Martini',
      note:      'changed by my self',
    )

    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert(ExternalSync.find_by(source: 'clearbit', object: 'User', o_id: customer2.id))

    customer2.reload

    assert_equal('Martini', customer2.firstname)
    assert_equal('Edenhofer', customer2.lastname)
    assert_equal('changed by my self', customer2.note)
    assert_equal('Norsk-Data-Straße 1, 61352 Bad Homburg vor der Höhe, Germany', customer2.address)

    customer2_enrichment = Enrichment::Clearbit::User.new(customer2)
    customer2_enrichment.synced?
    Scheduler.worker(true)

    customer2.reload

    assert_equal('Martini', customer2.firstname)
    assert_equal('Edenhofer', customer2.lastname)
    assert_equal('changed by my self', customer2.note)
    assert_equal('Norsk-Data-Straße 1, 61352 Bad Homburg vor der Höhe, Germany', customer2.address)

    # update with own values (do not overwrite)
    customer2.update!(
      firstname: '',
      note:      'changed by my self',
    )

    customer2_enrichment = Enrichment::Clearbit::User.new(customer2)
    customer2_enrichment.synced?
    Scheduler.worker(true)

    customer2.reload

    assert_equal('Martin', customer2.firstname)
    assert_equal('Edenhofer', customer2.lastname)
    assert_equal('changed by my self', customer2.note)
    assert_equal('Norsk-Data-Straße 1, 61352 Bad Homburg vor der Höhe, Germany', customer2.address)

    # update with changed values at clearbit site (do overwrite)
    customer2.update!(
      email: 'me2@example.com',
    )

    customer2_enrichment = Enrichment::Clearbit::User.new(customer2)
    customer2_enrichment.synced?
    Scheduler.worker(true)

    customer2.reload

    assert_equal('Martini', customer2.firstname)
    assert_equal('Edenhofer', customer2.lastname)
    assert_equal('changed by my self', customer2.note)
    assert_equal('Norsk-Data-Straße 1, 61352 Bad Homburg vor der Höhe, Germany', customer2.address)

    organization2 = Organization.find_by(name: 'OTRS AG')
    assert(ExternalSync.find_by(source: 'clearbit', object: 'Organization', o_id: organization2.id))
    assert_equal(false, organization2.shared)
    assert_equal('OTRS is an Open Source helpdesk software and an IT Service Management software free of licence costs. Improve your Customer Service Management with OTRS.', organization2.note)

    # case 3 - no person
    customer3 = User.create!(
      firstname:     '',
      lastname:      '',
      email:         'testing3@znuny.com',
      note:          '',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(customer3)

    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert_not(ExternalSync.find_by(source: 'clearbit', object: 'User', o_id: customer3.id))

    customer3.reload

    assert_equal('', customer3.firstname)
    assert_equal('', customer3.lastname)
    assert_equal('', customer3.note)
    assert_equal('http://znuny.com', customer3.web)
    assert_equal('Marienstraße 11, 10117 Berlin, Germany', customer3.address)

    organization3 = Organization.find_by(name: 'Znuny / ES for OTRS')
    assert(ExternalSync.find_by(source: 'clearbit', object: 'Organization', o_id: organization3.id))
    assert_equal(false, organization3.shared)
    assert_equal('OTRS Support, Consulting, Development, Training and Customizing - Znuny GmbH', organization3.note)

    # case 4 - person with organization but organization is already assigned (own created)
    customer4 = User.create!(
      firstname:       '',
      lastname:        '',
      email:           'testing4@znuny.com',
      note:            '',
      organization_id: 1,
      updated_by_id:   1,
      created_by_id:   1,
    )
    assert(customer4)

    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert(ExternalSync.find_by(source: 'clearbit', object: 'User', o_id: customer4.id))

    customer4.reload

    assert_equal('Fred', customer4.firstname)
    assert_equal('Jupiter', customer4.lastname)
    assert_equal('some_fred_bio', customer4.note)
    assert_equal('http://fred.znuny.com', customer4.web)
    assert_equal('Marienstraße 11, 10117 Berlin, Germany', customer4.address)

    organization4 = Organization.find_by(name: 'ZnunyOfFred')
    assert_not(organization4)

    # case 5 - person with organization but organization is already assigned (own created)
    customer5 = User.create!(
      firstname:       '',
      lastname:        '',
      email:           'testing5@znuny.com',
      note:            '',
      organization_id: organization3.id,
      updated_by_id:   1,
      created_by_id:   1,
    )
    assert(customer5)

    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert(ExternalSync.find_by(source: 'clearbit', object: 'User', o_id: customer5.id))

    customer5.reload

    assert_equal('Alex', customer5.firstname)
    assert_equal('Dont', customer5.lastname)
    assert_equal('some_bio_alex', customer5.note)
    assert_equal('http://znuny.com', customer5.web)
    assert_equal('Marienstraße 11, 10117 Berlin, Germany', customer5.address)

    organization5 = Organization.find_by(name: 'Znuny GmbH')
    assert_equal(organization3.id, organization5.id)
    assert(ExternalSync.find_by(source: 'clearbit', object: 'Organization', o_id: organization5.id))
    assert_equal(false, organization5.shared)
    assert_equal('OTRS Support, Consulting, Development, Training and Customizing - Znuny GmbH', organization5.note)

    # case 6 - no person / real api call
    customer6 = User.create!(
      firstname:     '',
      lastname:      '',
      email:         'testing6@clearbit.com',
      note:          '',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(customer6)

    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert_not(ExternalSync.find_by(source: 'clearbit', object: 'User', o_id: customer6.id))

    customer6.reload

    assert_equal('', customer6.firstname)
    assert_equal('', customer6.lastname)
    assert_equal('', customer6.note)
    assert_equal('', customer6.web)
    #assert_equal('http://clearbit.com', customer6.web)
    sometimes_changing_but_valid_addresses = [
      'San Francisco, CA, USA',
      'San Francisco, CA 94103, USA',
      '90 Sheridan St, San Francisco, CA 94103, USA',
      '3030 16th St, San Francisco, CA 94103, USA',
    ]
    assert_includes(sometimes_changing_but_valid_addresses, customer6.address)

    organization6 = Organization.find_by('name LIKE ?', 'APIHub, Inc%')
    assert(ExternalSync.find_by(source: 'clearbit', object: 'Organization', o_id: organization6.id))
    assert_equal(false, organization6.shared)
    assert_equal('The marketing data engine to deeply understand your customers, identify future prospects, &amp; personalize every single marketing &amp; sales interaction.', organization6.note)

  end

  # check
  test 'base with invalid input' do
    if !ENV['CLEARBIT_CI_API_KEY']
      raise "ERROR: Need CLEARBIT_CI_API_KEY - hint CLEARBIT_CI_API_KEY='abc...'"
    end

    # set system mode to done / to activate
    Setting.set('system_init_done', true)

    Setting.set('clearbit_integration', true)
    Setting.set('clearbit_config', {
                  api_key:                 ENV['CLEARBIT_CI_API_KEY'],
                  organization_autocreate: true,
                  organization_shared:     true,
                  user_sync:               {
                    'person.name.givenName'  => 'user.firstname',
                    'person.name.familyName' => 'user.lastname',
                    'person.email'           => 'user.email',
                    'person.bio'             => 'user.note_not_existing',
                    'company.url'            => 'user.web',
                    'person.site'            => 'user.web',
                    'company.location'       => 'user.address',
                    'person.location'        => 'user.address',
                  },
                  organization_sync:       {
                    'company.legalName'   => 'organization.name',
                    'company.name'        => 'organization.name',
                    'company.description' => 'organization.note_not_existing',
                  },
                })

    # case 1 - person + company (demo data set)
    customer1 = User.create!(
      firstname:     '',
      lastname:      'Should be still there',
      email:         'testing6@znuny.com',
      note:          '',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(customer1)

    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert(ExternalSync.find_by(source: 'clearbit', object: 'User', o_id: customer1.id))

    customer1.reload

    assert_equal('Should', customer1.firstname)
    assert_equal('be still there', customer1.lastname)
    assert_equal('', customer1.note)
    assert_equal('Marienstraße 11, 10117 Berlin, Germany', customer1.address)

    organization1 = Organization.find_by(name: 'Znuny2')
    assert(ExternalSync.find_by(source: 'clearbit', object: 'Organization', o_id: organization1.id))
    assert_equal(true, organization1.shared)
    assert_equal('', organization1.note)
  end

end
