# encoding: utf-8
require 'test_helper'

class TicketCustomerOrganizationUpdateTest < ActiveSupport::TestCase

  setup do
    groups = Group.where(name: 'Users')
    roles  = Role.where(name: 'Agent')
    @agent1 = User.create_or_update(
      login: 'ticket-customer-organization-update-agent1@example.com',
      firstname: 'Notification',
      lastname: 'Agent1',
      email: 'ticket-customer-organization-update-agent1@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    roles = Role.where(name: 'Customer')
    @organization1 = Organization.create_if_not_exists(
      name: 'Customer Organization Update',
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    @customer1 = User.create_or_update(
      login: 'ticket-customer-organization-update-customer1@example.com',
      firstname: 'Notification',
      lastname: 'Customer1',
      email: 'ticket-customer-organization-update-customer1@example.com',
      password: 'customerpw',
      active: true,
      organization_id: @organization1.id,
      roles: roles,
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

  test 'create ticket, update customers organization later' do

    ticket = Ticket.create(
      title: "some title1\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer_id: @customer1.id,
      owner_id: @agent1.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket, 'ticket created')
    assert_equal(@customer1.id, ticket.customer.id)
    assert_equal(@organization1.id, ticket.organization.id)

    # update customer organization
    @customer1.organization_id = nil
    @customer1.save!

    # verify ticket
    ticket.reload
    assert_nil(ticket.organization_id)

    # update customer organization
    @customer1.organization_id = @organization1.id
    @customer1.save!

    # verify ticket
    ticket.reload
    assert_equal(@organization1.id, ticket.organization_id)

    ticket.destroy
  end
end
