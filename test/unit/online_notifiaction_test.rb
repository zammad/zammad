# encoding: utf-8
require 'test_helper'

class OnlineNotificationTest < ActiveSupport::TestCase
  role        = Role.lookup( :name => 'Agent' )
  group       = Group.lookup( :name => 'Users' )
  agent_user1 = User.create_or_update(
    :login         => 'agent_online_notify1',
    :firstname     => 'Bob',
    :lastname      => 'Smith',
    :email         => 'agent_online_notify1@example.com',
    :password      => 'some_pass',
    :active        => true,
    :role_ids      => [role.id],
    :group_ids     => [group.id],
    :updated_by_id => 1,
    :created_by_id => 1
  )
  agent_user2 = User.create_or_update(
    :login         => 'agent_online_notify2',
    :firstname     => 'Bob',
    :lastname      => 'Smith',
    :email         => 'agent_online_notify2@example.com',
    :password      => 'some_pass',
    :active        => true,
    :role_ids      => [role.id],
    :group_ids     => [group.id],
    :updated_by_id => 1,
    :created_by_id => 1
  )
  customer_user = User.lookup( :login => 'nicole.braun@zammad.org' )

  test 'ticket notifiaction' do
    tests = [

      # test 1
      {
        :create => {
          :ticket => {
            :group_id       => Group.lookup( :name => 'Users' ).id,
            :customer_id    => customer_user.id,
            :owner_id       => User.lookup( :login => '-' ).id,
            :title          => 'Unit Test 1 (äöüß)!',
            :state_id       => Ticket::State.lookup( :name => 'new' ).id,
            :priority_id    => Ticket::Priority.lookup( :name => '2 normal' ).id,
            :updated_by_id  => agent_user1.id,
            :created_by_id  => agent_user1.id,
          },
          :article => {
            :updated_by_id  => agent_user1.id,
            :created_by_id  => agent_user1.id,
            :type_id        => Ticket::Article::Type.lookup( :name => 'phone' ).id,
            :sender_id      => Ticket::Article::Sender.lookup( :name => 'Customer' ).id,
            :from           => 'Unit Test <unittest@example.com>',
            :body           => 'Unit Test 123',
            :internal       => false
          },
        },
        :update => {
          :ticket => {
            :title       => 'Unit Test 1 (äöüß) - update!',
            :state_id    => Ticket::State.lookup( :name => 'open' ).id,
            :priority_id => Ticket::Priority.lookup( :name => '1 low' ).id,
            :updated_by_id  => customer_user.id,
          },
        },
        :check => [
         {
            :type          => 'create',
            :object        => 'Ticket',
            :created_by_id => agent_user1.id,
          },
         {
            :type          => 'update',
            :object        => 'Ticket',
            :created_by_id => customer_user.id,
          },
        ]
      },

      # test 2
      {
        :create => {
          :ticket => {
            :group_id       => Group.lookup( :name => 'Users' ).id,
            :customer_id    => customer_user.id,
            :owner_id       => User.lookup( :login => '-' ).id,
            :title          => 'Unit Test 2 (äöüß)!',
            :state_id       => Ticket::State.lookup( :name => 'new' ).id,
            :priority_id    => Ticket::Priority.lookup( :name => '2 normal' ).id,
            :updated_by_id  => agent_user1.id,
            :created_by_id  => agent_user1.id,
          },
          :article => {
            :updated_by_id  => agent_user1.id,
            :created_by_id  => agent_user1.id,
            :type_id        => Ticket::Article::Type.lookup( :name => 'phone' ).id,
            :sender_id      => Ticket::Article::Sender.lookup( :name => 'Customer' ).id,
            :from           => 'Unit Test <unittest@example.com>',
            :body           => 'Unit Test 123',
            :internal       => false
          },
        },
        :update => {
          :ticket => {
            :title       => 'Unit Test 2 (äöüß) - update!',
            :state_id    => Ticket::State.lookup( :name => 'open' ).id,
            :priority_id => Ticket::Priority.lookup( :name => '1 low' ).id,
            :updated_by_id  => customer_user.id,
          },
        },
        :check => [
         {
            :type          => 'create',
            :object        => 'Ticket',
            :created_by_id => agent_user1.id,
          },
         {
            :type          => 'update',
            :object        => 'Ticket',
            :created_by_id => customer_user.id,
          },
        ]
      },
    ]
    tickets = []
    tests.each { |test|

      ticket                 = Ticket.create( test[:create][:ticket] )
      test[:check][0][:o_id] = ticket.id
      test[:check][1][:o_id] = ticket.id

      test[:create][:article][:ticket_id] = ticket.id
      article = Ticket::Article.create( test[:create][:article] )

      assert_equal( ticket.class.to_s, 'Ticket' )

      # execute ticket events
      Observer::Ticket::Notification.transaction
      #puts Delayed::Job.all.inspect
      Delayed::Worker.new.work_off

      # update ticket
      if test[:update][:ticket]
        ticket.update_attributes( test[:update][:ticket] )
      end

      # execute ticket events
      Observer::Ticket::Notification.transaction
      #puts Delayed::Job.all.inspect
      Delayed::Worker.new.work_off

      # remember ticket
      tickets.push ticket

      # check online notifications
      notification_check( OnlineNotification.list(agent_user2, 10), test[:check] )
    }

    # merge tickets - also remove notifications of merged tickets
    tickets[0].merge_to(
      :ticket_id => tickets[1].id,
      :user_id   => 1,
    )
    notifications = OnlineNotification.list_by_object( 'Ticket', tickets[0].id, false )
    assert( notifications.empty?, "still not seen notifications for merged ticket available")

    notifications = OnlineNotification.list_by_object( 'Ticket', tickets[1].id, true )
    assert( notifications.empty?, "no notifications for master ticket available")


    # delete tickets
    tickets.each { |ticket|
      ticket_id = ticket.id
      ticket.destroy
      found = Ticket.where( :id => ticket_id ).first
      assert( !found, "Ticket destroyed")

      # check if notifications for ticket still exist
      notifications = OnlineNotification.list_by_object( 'Ticket', ticket_id )
      assert( notifications.empty?, "still notifications for destroyed ticket available")
    }
  end

  def notification_check( onine_notifications, checks )
    checks.each { |check_item|
      hit = false
      onine_notifications.each {|onine_notification|
        if onine_notification['o_id'] == check_item[:o_id]
          if onine_notification['object'] == check_item[:object]
            if onine_notification['type'] == check_item[:type]
              if onine_notification['created_by_id'] == check_item[:created_by_id]
                hit = true
              end
            end
          end
        end
      }
      assert( hit, "online notification exists #{ check_item.inspect }" )
    }
  end

end