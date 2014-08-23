# encoding: utf-8
require 'test_helper'

class RecentViewTest < ActiveSupport::TestCase

  test 'simple tests' do

    ticket1 = Ticket.create(
      :title          => 'RecentViewTest 1 some title äöüß',
      :group          => Group.lookup( :name => 'Users'),
      :customer_id    => 2,
      :state          => Ticket::State.lookup( :name => 'new' ),
      :priority       => Ticket::Priority.lookup( :name => '2 normal' ),
      :updated_by_id  => 1,
      :created_by_id  => 1,
    )
    assert( ticket1, "ticket created" )
    ticket2 = Ticket.create(
      :title          => 'RecentViewTest 2 some title äöüß',
      :group          => Group.lookup( :name => 'Users'),
      :customer_id    => 2,
      :state          => Ticket::State.lookup( :name => 'new' ),
      :priority       => Ticket::Priority.lookup( :name => '2 normal' ),
      :updated_by_id  => 1,
      :created_by_id  => 1,
    )
    assert( ticket2, "ticket created" )
    user1   = User.find(2)
    RecentView.user_log_destroy(user1)


    RecentView.log( ticket1.class.to_s, ticket1.id, user1 )
    sleep 1
    RecentView.log( ticket2.class.to_s, ticket2.id,, user1 )
    sleep 1
    RecentView.log( ticket1.class.to_s, ticket1.id, user1 )
    sleep 1
    RecentView.log( ticket1.class.to_s, ticket1.id, user1 )

    list = RecentView.list( user1 )
    assert( list[0]['o_id'], ticket1.id )
    assert( list[0]['object'], 'Ticket' )

    assert( list[1]['o_id'], ticket1.id )
    assert( list[1]['object'], 'Ticket' )

    assert( list[2]['o_id'], ticket2.id )
    assert( list[2]['object'], 'Ticket' )

    assert( list[3]['o_id'], ticket1.id )
    assert( list[3]['object'], 'Ticket' )

    ticket1.destroy
    ticket2.destroy

    list = RecentView.list( user1 )
    assert( !list[0], 'check if recent view list is empty' )
  end
end
