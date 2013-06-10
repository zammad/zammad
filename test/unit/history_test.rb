# encoding: utf-8
require 'test_helper'

class HistoryTest < ActiveSupport::TestCase
  test 'ticket' do
    tests = [

      # test 1
      {
        :ticket_create => {
          :ticket => {
            :group_id           => Group.lookup( :name => 'Users' ).id,
            :customer_id        => User.lookup( :login => 'nicole.braun@zammad.org' ).id,
            :owner_id           => User.lookup( :login => '-' ).id,
            :title              => 'Unit Test 1 (äöüß)!',
            :ticket_state_id    => Ticket::State.lookup( :name => 'new' ).id,
            :ticket_priority_id => Ticket::Priority.lookup( :name => '2 normal' ).id,
            :updated_by_id      => User.lookup( :login => 'nicole.braun@zammad.org' ).id,
            :created_by_id      => User.lookup( :login => 'nicole.braun@zammad.org' ).id,
          },
          :article => {
              :updated_by_id            => User.lookup( :login => 'nicole.braun@zammad.org' ).id,
              :created_by_id            => User.lookup( :login => 'nicole.braun@zammad.org' ).id,
              :ticket_article_type_id   => Ticket::Article::Type.lookup( :name => 'phone' ).id,
              :ticket_article_sender_id => Ticket::Article::Sender.lookup( :name => 'Customer' ).id,
              :from                     => 'Unit Test <unittest@example.com>',
              :body                     => 'Unit Test 123',
              :internal                 => false
          },
        },
        :ticket_update => {
          :ticket => {
            :title              => 'Unit Test 1 (äöüß) - update!',
            :ticket_state_id    => Ticket::State.lookup( :name => 'open' ).id,
            :ticket_priority_id => Ticket::Priority.lookup( :name => '1 low' ).id,
          },
        },
        :history_check => [
          {
            :history_object => 'Ticket',
            :history_type   => 'created',
          },
          {
            :history_object    => 'Ticket',
            :history_type      => 'updated',
            :history_attribute => 'title',
            :value_from        => 'Unit Test 1 (äöüß)!',
            :value_to          => 'Unit Test 1 (äöüß) - update!',
          },
          {
            :history_object    => 'Ticket',
            :history_type      => 'updated',
            :history_attribute => 'ticket_state',
            :value_from        => 'new',
            :value_to          => 'open',
            :id_from           => Ticket::State.lookup( :name => 'new' ).id,
            :id_to             => Ticket::State.lookup( :name => 'open' ).id,
          },
          {
            :history_object => 'Ticket::Article',
            :history_type   => 'created',
          },
        ]
      },

      # test 2
      {
        :ticket_create => {
          :ticket => {
            :group_id           => Group.lookup( :name => 'Users' ).id,
            :customer_id        => User.lookup( :login => 'nicole.braun@zammad.org' ).id,
            :owner_id           => User.lookup( :login => '-' ).id,
            :title              => 'Unit Test 2 (äöüß)!',
            :ticket_state_id    => Ticket::State.lookup( :name => 'new' ).id,
            :ticket_priority_id => Ticket::Priority.lookup( :name => '2 normal' ).id,
            :updated_by_id      => User.lookup( :login => 'nicole.braun@zammad.org' ).id,
            :created_by_id      => User.lookup( :login => 'nicole.braun@zammad.org' ).id,
          },
          :article => {
              :created_by_id            => User.lookup( :login => 'nicole.braun@zammad.org' ).id,
              :updated_by_id            => User.lookup( :login => 'nicole.braun@zammad.org' ).id,
              :ticket_article_type_id   => Ticket::Article::Type.lookup(:name => 'phone' ).id,
              :ticket_article_sender_id => Ticket::Article::Sender.lookup(:name => 'Customer' ).id,
              :from                     => 'Unit Test <unittest@example.com>',
              :body                     => 'Unit Test 123',
              :internal                 => false
          },
        },
        :ticket_update => {
          :ticket => {
            :title              => 'Unit Test 2 (äöüß) - update!',
            :ticket_state_id    => Ticket::State.lookup( :name => 'open' ).id,
            :owner_id           => User.lookup( :login => 'nicole.braun@zammad.org' ).id,
          },
          :article => {
            :from               => 'Unit 2 Test 2 <unittest@example.com>',
          },
        },
        :history_check => [
          {
            :history_object => 'Ticket',
            :history_type   => 'created',
          },
          {
            :history_object    => 'Ticket',
            :history_type      => 'updated',
            :history_attribute => 'title',
            :value_from        => 'Unit Test 2 (äöüß)!',
            :value_to          => 'Unit Test 2 (äöüß) - update!',
          },
          {
            :history_object    => 'Ticket',
            :history_type      => 'updated',
            :history_attribute => 'owner',
            :value_from        => '-',
            :value_to          => 'Nicole Braun',
            :id_from           => User.lookup( :login => '-' ).id,
            :id_to             => User.lookup( :login => 'nicole.braun@zammad.org' ).id,
          },
          {
            :history_object => 'Ticket::Article',
            :history_type   => 'created',
          },
          {
            :history_object    => 'Ticket::Article',
            :history_type      => 'updated',
            :history_attribute => 'from',
            :value_from        => 'Unit Test <unittest@example.com>',
            :value_to          => 'Unit 2 Test 2 <unittest@example.com>',
          },
        ]
      },
    ]
    tickets = []
    tests.each { |test|

      ticket = nil
      article = nil

      # use transaction
      ActiveRecord::Base.transaction do
        ticket = Ticket.create( test[:ticket_create][:ticket])
        test[:ticket_create][:article][:ticket_id] = ticket.id
        article = Ticket::Article.create( test[:ticket_create][:article] )

        assert_equal( ticket.class.to_s, 'Ticket' )
        assert_equal( article.class.to_s, 'Ticket::Article' )

        # update ticket
        if test[:ticket_update][:ticket]
          ticket.update_attributes( test[:ticket_update][:ticket] )
        end
        if test[:ticket_update][:article]
          article.update_attributes( test[:ticket_update][:article] )
        end
      end

      # execute ticket events
      Observer::Ticket::Notification.transaction

      # remember ticket
      tickets.push ticket

      # get history
      history_list = History.list( 'Ticket', ticket.id, 'Ticket::Article' )
      puts history_list.inspect
      test[:history_check].each { |check_item|
#        puts '+++++++++++'
#        puts check_item.inspect
        match = false
        history_list.each { |history_item|
          next if match
#          puts '--------'
#          puts history_item.inspect
          next if history_item['history_object'] != check_item[:history_object]
          next if history_item['history_type'] != check_item[:history_type]
          next if check_item[:history_attribute] != history_item['history_attribute']
          match = true
          if history_item['history_type'] == check_item[:history_type]
            assert( true, "History type #{history_item['history_type']} found!")
          end
          if check_item[:history_attribute]
            assert_equal( check_item[:history_attribute], history_item['history_attribute'], "check history attribute #{check_item[:history_attribute]}")
          end
          if check_item[:value_from]
            assert_equal( check_item[:value_from], history_item['value_from'], "check history :value_from #{history_item['value_from']} ok")
          end
          if check_item[:value_to]
            assert_equal( check_item[:value_to], history_item['value_to'], "check history :value_to #{history_item['value_to']} ok")
          end
          if check_item[:id_from]
            assert_equal( check_item[:id_from], history_item['id_from'], "check history :id_from #{history_item['id_from']} ok")
          end
          if check_item[:id_to]
            assert_equal( check_item[:id_to], history_item['id_to'], "check history :id_to #{history_item['id_to']} ok")
          end
        }
        assert( match, "history check not matched! #{check_item.inspect}")
      }
    }

    # delete tickets
    tickets.each { |ticket|
      ticket_id = ticket.id
      ticket.destroy
      found = Ticket.where( :id => ticket_id ).first
      assert( !found, "Ticket destroyed")
    }
  end
end
