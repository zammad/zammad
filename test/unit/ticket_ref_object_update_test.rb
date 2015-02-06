# encoding: utf-8
require 'test_helper'

class TicketRefObjectTouchTest < ActiveSupport::TestCase

  # create base
  groups = Group.where( :name => 'Users' )
  roles  = Role.where( :name => 'Agent' )
  agent1 = User.create_or_update(
    :login         => 'ticket-ref-object-update-agent1@example.com',
    :firstname     => 'Notification',
    :lastname      => 'Agent1',
    :email         => 'ticket-ref-object-update-agent1@example.com',
    :password      => 'agentpw',
    :active        => true,
    :roles         => roles,
    :groups        => groups,
    :updated_at    => '2015-02-05 16:37:00',
    :updated_by_id => 1,
    :created_by_id => 1,
  )
  roles  = Role.where( :name => 'Customer' )
  customer1 = User.create_or_update(
    :login         => 'ticket-ref-object-update-customer1@example.com',
    :firstname     => 'Notification',
    :lastname      => 'Agent1',
    :email         => 'ticket-ref-object-update-customer1@example.com',
    :password      => 'customerpw',
    :active        => true,
    :roles         => roles,
    :updated_at    => '2015-02-05 16:37:00',
    :updated_by_id => 1,
    :created_by_id => 1,
  )
  organization1 = Organization.create_if_not_exists(
    :name          => 'Ref Object Update Org',
    :updated_at    => '2015-02-05 16:37:00',
    :updated_by_id => 1,
    :created_by_id => 1,
  )

  test 'check if customer and organization has been updated' do

    ticket = Ticket.create(
      :title         => "some title\n äöüß",
      :group         => Group.lookup( :name => 'Users'),
      :customer_id   => customer1.id,
      :owner_id      => agent1.id,
      :state         => Ticket::State.lookup( :name => 'new' ),
      :priority      => Ticket::Priority.lookup( :name => '2 normal' ),
      :updated_by_id => 1,
      :created_by_id => 1,
    )
    assert( ticket, "ticket created" )

    # check if customer and organization has been touched
    customer1 = User.find(customer1.id)
    if customer1.updated_at > 2.second.ago
      assert( true, "customer1.updated_at has been updated" )
    else
      assert( false, "customer1.updated_at has not been updated" )
    end

    organization1 = Organization.find(organization1.id)
    if organization1.updated_at > 2.second.ago
      assert( true, "organization1.updated_at has been updated" )
    else
      assert( false, "organization1.updated_at has not been updated" )
    end

    sleep 5

    delete = ticket.destroy
    assert( delete, "ticket destroy" )

    # check if customer and organization has been touched
    customer1 = User.find(customer1.id)
    if customer1.updated_at > 2.second.ago
      assert( true, "customer1.updated_at has been updated" )
    else
      assert( false, "customer1.updated_at has not been updated" )
    end

    organization1 = Organization.find(organization1.id)
    if organization1.updated_at > 2.second.ago
      assert( true, "organization1.updated_at has been updated" )
    else
      assert( false, "organization1.updated_at has not been updated" )
    end

  end
end