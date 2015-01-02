# encoding: utf-8
require 'test_helper'

class TicketNotificationTest < ActiveSupport::TestCase
  test 'ticket create' do

    # create agent1 & agent2
    groups = Group.where( :name => 'Users' )
    roles  = Role.where( :name => 'Agent' )
    agent1  = User.create_or_update(
      :login         => 'ticket-notification-agent1@example.com',
      :firstname     => 'Notification',
      :lastname      => 'Agent1',
      :email         => 'ticket-notification-agent1@example.com',
      :password      => 'agentpw',
      :active        => true,
      :roles         => roles,
      :groups        => groups,
      :updated_by_id => 1,
      :created_by_id => 1,
    )
    agent2  = User.create_or_update(
      :login         => 'ticket-notification-agent2@example.com',
      :firstname     => 'Notification',
      :lastname      => 'Agent2',
      :email         => 'ticket-notification-agent2@example.com',
      :password      => 'agentpw',
      :active        => true,
      :roles         => roles,
      :groups        => groups,
      :updated_by_id => 1,
      :created_by_id => 1,
    )
    Group.create_if_not_exists(
      :name          => 'WithoutAccess',
      :note          => 'Test for notification check.',
      :updated_by_id => 1,
      :created_by_id => 1
    )

    # create customer
    roles  = Role.where( :name => 'Customer' )
    customer  = User.create_or_update(
      :login         => 'ticket-notification-customer@example.com',
      :firstname     => 'Notification',
      :lastname      => 'Customer',
      :email         => 'ticket-notification-customer@example.com',
      :password      => 'agentpw',
      :active        => true,
      :roles         => roles,
      :groups        => groups,
      :updated_by_id => 1,
      :created_by_id => 1,
    )

    # create ticket in group
    ticket1 = Ticket.create(
      :title         => 'some notification test 1',
      :group         => Group.lookup( :name => 'Users'),
      :customer      => customer,
      :state         => Ticket::State.lookup( :name => 'new' ),
      :priority      => Ticket::Priority.lookup( :name => '2 normal' ),
      :updated_by_id => customer.id,
      :created_by_id => customer.id,
    )
    article_inbound = Ticket::Article.create(
      :ticket_id     => ticket1.id,
      :from          => 'some_sender@example.com',
      :to            => 'some_recipient@example.com',
      :subject       => 'some subject',
      :message_id    => 'some@id',
      :body          => 'some message',
      :internal      => false,
      :sender        => Ticket::Article::Sender.where(:name => 'Customer').first,
      :type          => Ticket::Article::Type.where(:name => 'email').first,
      :updated_by_id => customer.id,
      :created_by_id => customer.id,
    )
    assert( ticket1, "ticket created" )

    # execute ticket events
    Observer::Ticket::Notification.transaction
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off

    # verify notifications to agent1 + agent2
    assert_equal( 1, notification_check(ticket1, agent1), 'agent 1 notification count check' )
    assert_equal( 1, notification_check(ticket1, agent2), 'agent 2 notification count check' )

    # update ticket attributes
    ticket1.title    = "#{ticket1.title} - #2"
    ticket1.priority = Ticket::Priority.lookup( :name => '3 high' )
    ticket1.save

    # execute ticket events
    Observer::Ticket::Notification.transaction
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off

    # verify notifications to agent1 + agent2
    assert_equal( 2, notification_check(ticket1, agent1), 'agent 1 notification count check' )
    assert_equal( 2, notification_check(ticket1, agent2), 'agent 2 notification count check' )

    # add article to ticket
    article_note = Ticket::Article.create(
      :ticket_id      => ticket1.id,
      :from           => 'some person',
      :subject        => 'some note',
      :body           => 'some message',
      :internal       => true,
      :sender         => Ticket::Article::Sender.where(:name => 'Agent').first,
      :type           => Ticket::Article::Type.where(:name => 'note').first,
      :updated_by_id  => 1,
      :created_by_id  => 1,
    )

    # verify notifications to agent1 + agent2



    # create ticket with agent1 as owner
    ticket2 = Ticket.create(
      :title          => 'some notification test 2',
      :group          => Group.lookup( :name => 'Users'),
      :customer_id    => 2,
      :owner_id       => agent1.id,
      :state          => Ticket::State.lookup( :name => 'new' ),
      :priority       => Ticket::Priority.lookup( :name => '2 normal' ),
      :updated_by_id  => agent1.id,
      :created_by_id  => agent1.id,
    )
    article_inbound = Ticket::Article.create(
      :ticket_id     => ticket2.id,
      :from          => 'some_sender@example.com',
      :to            => 'some_recipient@example.com',
      :subject       => 'some subject',
      :message_id    => 'some@id',
      :body          => 'some message',
      :internal      => false,
      :sender        => Ticket::Article::Sender.where(:name => 'Agent').first,
      :type          => Ticket::Article::Type.where(:name => 'phone').first,
      :updated_by_id => agent1.id,
      :created_by_id => agent1.id,
    )

    # execute ticket events
    Observer::Ticket::Notification.transaction
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off
    assert( ticket2, "ticket created" )

    # verify notifications to no one
    assert_equal( 0, notification_check(ticket2, agent1), 'agent 1 notification count check' )
    assert_equal( 0, notification_check(ticket2, agent2), 'agent 2 notification count check' )

    # update ticket
    ticket2.title         = "#{ticket2.title} - #2"
    ticket2.updated_by_id = agent1.id
    ticket2.priority      = Ticket::Priority.lookup( :name => '3 high' )
    ticket2.save

    # execute ticket events
    Observer::Ticket::Notification.transaction
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off

    # verify notifications to no one
    assert_equal( 0, notification_check(ticket2, agent1), 'agent 1 notification count check' )
    assert_equal( 0, notification_check(ticket2, agent2), 'agent 2 notification count check' )

    # update ticket
    ticket2.title         = "#{ticket2.title} - #3"
    ticket2.updated_by_id = agent2.id
    ticket2.priority      = Ticket::Priority.lookup( :name => '2 normal' )
    ticket2.save

    # execute ticket events
    Observer::Ticket::Notification.transaction
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off

    # verify notifications to agent1 and not to agent2
    assert_equal( 1, notification_check(ticket2, agent1), 'agent 1 notification count check' )
    assert_equal( 0, notification_check(ticket2, agent2), 'agent 2 notification count check' )



    # create ticket with agent2 and agent1 as owner
    ticket3 = Ticket.create(
      :title          => 'some notification test 3',
      :group          => Group.lookup( :name => 'Users'),
      :customer_id    => 2,
      :owner_id       => agent1.id,
      :state          => Ticket::State.lookup( :name => 'new' ),
      :priority       => Ticket::Priority.lookup( :name => '2 normal' ),
      :updated_by_id  => agent2.id,
      :created_by_id  => agent2.id,
    )
    article_inbound = Ticket::Article.create(
      :ticket_id     => ticket3.id,
      :from          => 'some_sender@example.com',
      :to            => 'some_recipient@example.com',
      :subject       => 'some subject',
      :message_id    => 'some@id',
      :body          => 'some message',
      :internal      => false,
      :sender        => Ticket::Article::Sender.where(:name => 'Agent').first,
      :type          => Ticket::Article::Type.where(:name => 'phone').first,
      :updated_by_id => agent2.id,
      :created_by_id => agent2.id,
    )

    # execute ticket events
    Observer::Ticket::Notification.transaction
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off
    assert( ticket3, "ticket created" )

    # verify notifications to agent1 and not to agent2
    assert_equal( 1, notification_check(ticket3, agent1), 'agent 1 notification count check' )
    assert_equal( 0, notification_check(ticket3, agent2), 'agent 2 notification count check' )

    # update ticket
    ticket3.title         = "#{ticket3.title} - #2"
    ticket3.updated_by_id = agent1.id
    ticket3.priority      = Ticket::Priority.lookup( :name => '3 high' )
    ticket3.save

    # execute ticket events
    Observer::Ticket::Notification.transaction
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off

    # verify notifications to no one
    assert_equal( 1, notification_check(ticket3, agent1), 'agent 1 notification count check' )
    assert_equal( 0, notification_check(ticket3, agent2), 'agent 2 notification count check' )

    # update ticket
    ticket3.title         = "#{ticket3.title} - #3"
    ticket3.updated_by_id = agent2.id
    ticket3.priority      = Ticket::Priority.lookup( :name => '2 normal' )
    ticket3.save

    # execute ticket events
    Observer::Ticket::Notification.transaction
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off

    # verify notifications to agent1 and not to agent2
    assert_equal( 2, notification_check(ticket3, agent1), 'agent 1 notification count check' )
    assert_equal( 0, notification_check(ticket3, agent2), 'agent 2 notification count check' )


    delete = ticket1.destroy
    assert( delete, "ticket1 destroy" )

    delete = ticket2.destroy
    assert( delete, "ticket2 destroy" )

    delete = ticket3.destroy
    assert( delete, "ticket3 destroy" )

  end

  def notification_check(ticket, recipient)
    result = ticket.history_get()
    count  = 0
    result.each {|item|
      next if item['type'] != 'notification'
      next if item['object'] != 'Ticket'
      next if item['value_to'] !~ /#{recipient.email}/i
      count += 1
    }
    count
  end
end