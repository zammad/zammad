# encoding: utf-8
require 'test_helper'

class OrganizationRefObjectTouchTest < ActiveSupport::TestCase

  test 'check if ticket and customer has been updated' do

    # create base
    groups = Group.where(name: 'Users')
    roles  = Role.where(name: 'Agent')
    agent1 = User.create_or_update(
      login: 'organization-ref-object-update-agent1@example.com',
      firstname: 'Notification',
      lastname: 'Agent1',
      email: 'organization-ref-object-update-agent1@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    roles = Role.where(name: 'Customer')
    organization1 = Organization.create_if_not_exists(
      name: 'Ref Object Update Org 1',
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    organization2 = Organization.create_if_not_exists(
      name: 'Ref Object Update Org 2',
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    customer1 = User.create_or_update(
      login: 'organization-ref-object-update-customer1@example.com',
      firstname: 'Notification',
      lastname: 'Agent1',
      email: 'organization-ref-object-update-customer1@example.com',
      password: 'customerpw',
      active: true,
      organization_id: organization1.id,
      roles: roles,
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    customer2 = User.create_or_update(
      login: 'organization-ref-object-update-customer2@example.com',
      firstname: 'Notification',
      lastname: 'Agent2',
      email: 'organization-ref-object-update-customer2@example.com',
      password: 'customerpw',
      active: true,
      organization_id: organization2.id,
      roles: roles,
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket = Ticket.create(
      title: "some title1\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer_id: customer1.id,
      owner_id: agent1.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket, 'ticket created')
    assert_equal(ticket.customer.id, customer1.id)
    assert_equal(ticket.organization.id, organization1.id)

    travel 4.seconds

    organization1.name = 'Ref Object Update Org 1/1'
    organization1.save

    # check if ticket and customer has been touched
    ticket = Ticket.find(ticket.id)
    if ticket.updated_at > 2.seconds.ago
      assert(true, 'ticket.updated_at has been updated')
    else
      assert(false, 'ticket.updated_at has not been updated')
    end

    customer1 = User.find(customer1.id)
    if customer1.updated_at > 2.seconds.ago
      assert(true, 'customer1.updated_at has been updated')
    else
      assert(false, 'customer1.updated_at has not been updated')
    end

    travel 4.seconds

    customer2.organization_id = organization1.id
    customer2.save

    # check if customer1 and organization has been touched
    customer1 = User.find(customer1.id)
    if customer1.updated_at > 2.seconds.ago
      assert(true, 'customer1.updated_at has been updated')
    else
      assert(false, 'customer1.updated_at has not been updated')
    end

    organization1 = Organization.find(organization1.id)
    if organization1.updated_at > 2.seconds.ago
      assert(true, 'organization1.updated_at has been updated')
    else
      assert(false, 'organization1.updated_at has not been updated')
    end

    delete = ticket.destroy
    assert(delete, 'ticket destroy')
    travel_back
  end

  test 'check if ticket and customer has not been updated (different featrue propose)' do

    # create base
    groups = Group.where(name: 'Users')
    roles  = Role.where(name: 'Agent')
    agent1 = User.create_or_update(
      login: 'organization-ref-object-not-update-agent1@example.com',
      firstname: 'Notification',
      lastname: 'Agent1',
      email: 'organization-ref-object-not-update-agent1@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    roles = Role.where(name: 'Customer')
    organization1 = Organization.create_if_not_exists(
      name: 'Ref Object Update Org 1 (no update)',
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    organization2 = Organization.create_if_not_exists(
      name: 'Ref Object Update Org 2 (no update)',
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    customer1 = User.create_or_update(
      login: 'organization-ref-object-not-update-customer1@example.com',
      firstname: 'Notification',
      lastname: 'Agent1',
      email: 'organization-ref-object-not-update-customer1@example.com',
      password: 'customerpw',
      active: true,
      organization_id: organization1.id,
      roles: roles,
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    customer2 = User.create_or_update(
      login: 'organization-ref-object-not-update-customer2@example.com',
      firstname: 'Notification',
      lastname: 'Agent2',
      email: 'organization-ref-object-not-update-customer2@example.com',
      password: 'customerpw',
      active: true,
      organization_id: organization2.id,
      roles: roles,
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    (1..100).each { |count|
      User.create_or_update(
        login: "organization-ref-object-update-customer3-#{count}@example.com",
        firstname: 'Notification',
        lastname: 'Agent2',
        email: "organization-ref-object-update-customer3-#{count}@example.com",
        password: 'customerpw',
        active: true,
        organization_id: organization1.id,
        roles: roles,
        updated_at: '2015-02-05 16:37:00',
        updated_by_id: 1,
        created_by_id: 1,
      )
    }

    ticket = Ticket.create(
      title: "some title1\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer_id: customer1.id,
      owner_id: agent1.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_at: '2015-02-05 16:39:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket, 'ticket created')
    assert_equal(ticket.customer.id, customer1.id)
    assert_equal(ticket.organization.id, organization1.id)

    customer1 = User.find(customer1.id)
    assert_not_equal('2015-02-05 16:37:00 UTC', customer1.updated_at.to_s)
    customer1_updated_at = customer1.updated_at

    travel 4.seconds
    organization1.name = 'Ref Object Update Org 1 (no update)/1'
    organization1.save
    organization1_updated_at = organization1.updated_at

    # check if ticket and customer has been touched
    ticket = Ticket.find(ticket.id)
    assert_equal('2015-02-05 16:39:00 UTC', ticket.updated_at.to_s)

    customer1 = User.find(customer1.id)
    assert_equal(customer1_updated_at.to_s, customer1.updated_at.to_s)

    travel 4.seconds

    customer2.organization_id = organization1.id
    customer2.save

    # check if customer1 and organization has been touched
    customer1 = User.find(customer1.id)
    assert_equal(customer1_updated_at.to_s, customer1.updated_at.to_s)

    organization1 = Organization.find(organization1.id)
    assert_equal(organization1_updated_at.to_s, organization1.updated_at.to_s)

    delete = ticket.destroy
    assert(delete, 'ticket destroy')
    travel_back
  end

end
