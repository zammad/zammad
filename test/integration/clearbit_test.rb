# encoding: utf-8
require 'integration_test_helper'

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
                  api_key: ENV['CLEARBIT_CI_API_KEY'],
                  organization_autocreate: true,
                  organization_shared: false,
                  user_sync: {
                    'person.name.givenName' => 'user.firstname',
                    'person.name.familyName' => 'user.lastname',
                    'person.email' => 'user.email',
                    'person.bio' => 'user.note',
                    'company.url' => 'user.web',
                    'person.site' => 'user.web',
                    'company.location' => 'user.address',
                    'person.location' => 'user.address',
                    #'person.timeZone' => 'user.preferences[:timezone]',
                    #'person.gender' => 'user.preferences[:gender]',
                  },
                  organization_sync: {
                    'company.legalName' => 'organization.name',
                    'company.name' => 'organization.name',
                    'company.description' => 'organization.note',
                  },
                })

    # case 1 - person + company (demo data set)
    customer1 = User.create(
      firstname: '',
      lastname: 'Should be still there',
      email: 'alex@alexmaccaw.com',
      note: '',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(customer1)

    Observer::Transaction.commit
    Scheduler.worker(true)

    assert(ExternalSync.find_by(source: 'clearbit', object: 'User', o_id: customer1.id))

    customer1_lookup = User.lookup(id: customer1.id)

    assert_equal('Alex', customer1_lookup.firstname)
    assert_equal('Should be still there', customer1_lookup.lastname)
    assert_equal('O\'Reilly author, software engineer & traveller. Founder of https://clearbit.com', customer1_lookup.note)
    assert_equal('1455 Market Street, San Francisco, CA 94103, USA', customer1_lookup.address)

    organization1_lookup = Organization.find_by(name: 'Uber, Inc.')
    assert(ExternalSync.find_by(source: 'clearbit', object: 'Organization', o_id: organization1_lookup.id))
    assert_equal(false, organization1_lookup.shared)
    assert_equal('Uber is a mobile app connecting passengers with drivers for hire.', organization1_lookup.note)

    # case 2 - person + company
    customer2 = User.create(
      firstname: '',
      lastname: '',
      email: 'me@example.com',
      note: '',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(customer2)

    Observer::Transaction.commit
    Scheduler.worker(true)

    assert(ExternalSync.find_by(source: 'clearbit', object: 'User', o_id: customer2.id))

    customer2_lookup = User.lookup(id: customer2.id)

    assert_equal('Martin', customer2_lookup.firstname)
    assert_equal('Edenhofer', customer2_lookup.lastname)
    assert_equal("Open Source professional and geek. Also known as OTRS inventor. ;)\r\nEntrepreneur and Advisor for open source people in need.", customer2_lookup.note)
    assert_equal('Norsk-Data-Straße 1, 61352 Bad Homburg vor der Höhe, Germany', customer2_lookup.address)

    organization2_lookup = Organization.find_by(name: 'OTRS')
    assert(ExternalSync.find_by(source: 'clearbit', object: 'Organization', o_id: organization2_lookup.id))
    assert_equal(false, organization2_lookup.shared)
    assert_equal('OTRS is an Open Source helpdesk software and an IT Service Management software free of licence costs. Improve your Customer Service Management with OTRS.', organization2_lookup.note)

    # update with own values (do not overwrite)
    customer2.update_attributes(
      firstname: 'Martini',
      note: 'changed by my self',
    )

    Observer::Transaction.commit
    Scheduler.worker(true)

    assert(ExternalSync.find_by(source: 'clearbit', object: 'User', o_id: customer2.id))

    customer2_lookup = User.lookup(id: customer2.id)

    assert_equal('Martini', customer2_lookup.firstname)
    assert_equal('Edenhofer', customer2_lookup.lastname)
    assert_equal('changed by my self', customer2_lookup.note)
    assert_equal('Norsk-Data-Straße 1, 61352 Bad Homburg vor der Höhe, Germany', customer2_lookup.address)

    customer2_enrichment = Enrichment::Clearbit::User.new(customer2)
    customer2_enrichment.synced?
    Scheduler.worker(true)

    customer2_lookup = User.lookup(id: customer2.id)

    assert_equal('Martini', customer2_lookup.firstname)
    assert_equal('Edenhofer', customer2_lookup.lastname)
    assert_equal('changed by my self', customer2_lookup.note)
    assert_equal('Norsk-Data-Straße 1, 61352 Bad Homburg vor der Höhe, Germany', customer2_lookup.address)

    # update with own values (do not overwrite)
    customer2.update_attributes(
      firstname: '',
      note: 'changed by my self',
    )

    customer2_enrichment = Enrichment::Clearbit::User.new(customer2)
    customer2_enrichment.synced?
    Scheduler.worker(true)

    customer2_lookup = User.lookup(id: customer2.id)

    assert_equal('Martin', customer2_lookup.firstname)
    assert_equal('Edenhofer', customer2_lookup.lastname)
    assert_equal('changed by my self', customer2_lookup.note)
    assert_equal('Norsk-Data-Straße 1, 61352 Bad Homburg vor der Höhe, Germany', customer2_lookup.address)

    # update with changed values at clearbit site (do overwrite)
    customer2.update_attributes(
      email: 'me2@example.com',
    )

    customer2_enrichment = Enrichment::Clearbit::User.new(customer2)
    customer2_enrichment.synced?
    Scheduler.worker(true)

    customer2_lookup = User.lookup(id: customer2.id)

    assert_equal('Martini', customer2_lookup.firstname)
    assert_equal('Edenhofer', customer2_lookup.lastname)
    assert_equal('changed by my self', customer2_lookup.note)
    assert_equal('Norsk-Data-Straße 1, 61352 Bad Homburg vor der Höhe, Germany', customer2_lookup.address)

    organization2_lookup = Organization.find_by(name: 'OTRS AG')
    assert(ExternalSync.find_by(source: 'clearbit', object: 'Organization', o_id: organization2_lookup.id))
    assert_equal(false, organization2_lookup.shared)
    assert_equal('OTRS is an Open Source helpdesk software and an IT Service Management software free of licence costs. Improve your Customer Service Management with OTRS.', organization2_lookup.note)

    # case 3 - no person
    customer3 = User.create(
      firstname: '',
      lastname: '',
      email: 'testing3@znuny.com',
      note: '',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(customer3)

    Observer::Transaction.commit
    Scheduler.worker(true)

    assert_not(ExternalSync.find_by(source: 'clearbit', object: 'User', o_id: customer3.id))

    customer3_lookup = User.lookup(id: customer3.id)
    assert_not_equal(customer3.updated_at, customer3_lookup.updated_at)

    assert_equal('', customer3_lookup.firstname)
    assert_equal('', customer3_lookup.lastname)
    assert_equal('', customer3_lookup.note)
    assert_equal('http://znuny.com', customer3_lookup.web)
    assert_equal('Marienstraße 11, 10117 Berlin, Germany', customer3_lookup.address)

    organization3_lookup = Organization.find_by(name: 'Znuny / ES for OTRS')
    assert(ExternalSync.find_by(source: 'clearbit', object: 'Organization', o_id: organization3_lookup.id))
    assert_equal(false, organization3_lookup.shared)
    assert_equal('OTRS Support, Consulting, Development, Training and Customizing - Znuny GmbH', organization3_lookup.note)

    # case 4 - person with organization but organization is already assigned (own created)
    customer4 = User.create(
      firstname: '',
      lastname: '',
      email: 'testing4@znuny.com',
      note: '',
      organization_id: 1,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(customer4)

    Observer::Transaction.commit
    Scheduler.worker(true)

    assert(ExternalSync.find_by(source: 'clearbit', object: 'User', o_id: customer4.id))

    customer4_lookup = User.lookup(id: customer4.id)
    assert_not_equal(customer4.updated_at, customer4_lookup.updated_at)

    assert_equal('Fred', customer4_lookup.firstname)
    assert_equal('Jupiter', customer4_lookup.lastname)
    assert_equal('some_fred_bio', customer4_lookup.note)
    assert_equal('http://fred.znuny.com', customer4_lookup.web)
    assert_equal('Marienstraße 11, 10117 Berlin, Germany', customer4_lookup.address)

    organization4_lookup = Organization.find_by(name: 'ZnunyOfFred')
    assert_not(organization4_lookup)

    # case 5 - person with organization but organization is already assigned (own created)
    customer5 = User.create(
      firstname: '',
      lastname: '',
      email: 'testing5@znuny.com',
      note: '',
      organization_id: organization3_lookup.id,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(customer5)

    Observer::Transaction.commit
    Scheduler.worker(true)

    assert(ExternalSync.find_by(source: 'clearbit', object: 'User', o_id: customer5.id))

    customer5_lookup = User.lookup(id: customer5.id)
    assert_not_equal(customer5.updated_at, customer5_lookup.updated_at)

    assert_equal('Alex', customer5_lookup.firstname)
    assert_equal('Dont', customer5_lookup.lastname)
    assert_equal('some_bio_alex', customer5_lookup.note)
    assert_equal('http://znuny.com', customer5_lookup.web)
    assert_equal('Marienstraße 11, 10117 Berlin, Germany', customer5_lookup.address)

    organization5_lookup = Organization.find_by(name: 'Znuny GmbH')
    assert_equal(organization3_lookup.id, organization5_lookup.id)
    assert(ExternalSync.find_by(source: 'clearbit', object: 'Organization', o_id: organization5_lookup.id))
    assert_equal(false, organization5_lookup.shared)
    assert_equal('OTRS Support, Consulting, Development, Training and Customizing - Znuny GmbH', organization5_lookup.note)

    # case 6 - no person / real api call
    customer6 = User.create(
      firstname: '',
      lastname: '',
      email: 'testing6@clearbit.com',
      note: '',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(customer6)

    Observer::Transaction.commit
    Scheduler.worker(true)

    assert_not(ExternalSync.find_by(source: 'clearbit', object: 'User', o_id: customer6.id))

    customer6_lookup = User.lookup(id: customer6.id)
    assert_not_equal(customer6.updated_at, customer6_lookup.updated_at)

    assert_equal('', customer6_lookup.firstname)
    assert_equal('', customer6_lookup.lastname)
    assert_equal('', customer6_lookup.note)
    assert_equal('http://clearbit.com', customer6_lookup.web)
    assert_equal('3030 16th St, San Francisco, CA 94103, USA', customer6_lookup.address)
    #assert_equal('San Francisco, CA, USA', customer6_lookup.address)

    organization6_lookup = Organization.find_by(name: 'APIHub, Inc')
    assert(organization6_lookup, 'unable to find org of user')
    assert(ExternalSync.find_by(source: 'clearbit', object: 'Organization', o_id: organization6_lookup.id))
    assert_equal(false, organization6_lookup.shared)
    assert_equal('Clearbit provides powerful products and data APIs to help your business grow. Contact enrichment, lead generation, financial compliance, and more...', organization6_lookup.note)

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
                  api_key: ENV['CLEARBIT_CI_API_KEY'],
                  organization_autocreate: true,
                  organization_shared: true,
                  user_sync: {
                    'person.name.givenName' => 'user.firstname',
                    'person.name.familyName' => 'user.lastname',
                    'person.email' => 'user.email',
                    'person.bio' => 'user.note_not_existing',
                    'company.url' => 'user.web',
                    'person.site' => 'user.web',
                    'company.location' => 'user.address',
                    'person.location' => 'user.address',
                  },
                  organization_sync: {
                    'company.legalName' => 'organization.name',
                    'company.name' => 'organization.name',
                    'company.description' => 'organization.note_not_existing',
                  },
                })

    # case 1 - person + company (demo data set)
    customer1 = User.create(
      firstname: '',
      lastname: 'Should be still there',
      email: 'testing6@znuny.com',
      note: '',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(customer1)

    Observer::Transaction.commit
    Scheduler.worker(true)

    assert(ExternalSync.find_by(source: 'clearbit', object: 'User', o_id: customer1.id))

    customer1_lookup = User.lookup(id: customer1.id)

    assert_equal('Bob', customer1_lookup.firstname)
    assert_equal('Should be still there', customer1_lookup.lastname)
    assert_equal('', customer1_lookup.note)
    assert_equal('Marienstraße 11, 10117 Berlin, Germany', customer1_lookup.address)

    organization1_lookup = Organization.find_by(name: 'Znuny2')
    assert(ExternalSync.find_by(source: 'clearbit', object: 'Organization', o_id: organization1_lookup.id))
    assert_equal(true, organization1_lookup.shared)
    assert_equal('', organization1_lookup.note)
  end

end
