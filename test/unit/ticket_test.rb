# encoding: utf-8
require 'test_helper'
 
class TicketTest < ActiveSupport::TestCase
  test 'ticket create' do
    ticket = Ticket.create(
      :title           => 'some title äöüß',
      :group           => Group.lookup( :name => 'Users'),
      :customer_id     => 2,
      :ticket_state    => Ticket::State.lookup( :name => 'new' ),
      :ticket_priority => Ticket::Priority.lookup( :name => '2 normal' ),
      :updated_by_id   => 1,
      :created_by_id   => 1,
    )
    assert( ticket, "ticket created" )

    assert_equal( ticket.title, 'some title äöüß', 'ticket.title verify' )
    assert_equal( ticket.group.name, 'Users', 'ticket.group verify' )
    assert_equal( ticket.ticket_state.name, 'new', 'ticket.state verify' )

    # create inbound article
    article_inbound = Ticket::Article.create(
      :ticket_id              => ticket.id,
      :from                   => 'some_sender@example.com',
      :to                     => 'some_recipient@example.com',
      :subject                => 'some subject',
      :message_id             => 'some@id',
      :body                   => 'some message',
      :internal               => false,
      :ticket_article_sender  => Ticket::Article::Sender.where(:name => 'Customer').first,
      :ticket_article_type    => Ticket::Article::Type.where(:name => 'email').first,
      :updated_by_id          => 1,
      :created_by_id          => 1,
    )
    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.article_count, 1, 'ticket.article_count verify - inbound' )
    assert_equal( ticket.last_contact.to_s, article_inbound.created_at.to_s, 'ticket.last_contact verify - inbound' )
    assert_equal( ticket.last_contact_customer.to_s, article_inbound.created_at.to_s, 'ticket.last_contact_customer verify - inbound' )
    assert_equal( ticket.last_contact_agent, nil, 'ticket.last_contact_agent verify - inbound' )
    assert_equal( ticket.first_response, nil, 'ticket.first_response verify - inbound' )
    assert_equal( ticket.close_time, nil, 'ticket.close_time verify - inbound' )

    # create note article
    article_note = Ticket::Article.create(
      :ticket_id              => ticket.id,
      :from                   => 'some persion',
      :subject                => 'some note',
      :body                   => 'some message',
      :internal               => true,
      :ticket_article_sender  => Ticket::Article::Sender.where(:name => 'Agent').first,
      :ticket_article_type    => Ticket::Article::Type.where(:name => 'note').first,
      :updated_by_id          => 1,
      :created_by_id          => 1,
    )

    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.article_count, 2, 'ticket.article_count verify - note' )
    assert_equal( ticket.last_contact.to_s, article_inbound.created_at.to_s, 'ticket.last_contact verify - note' )
    assert_equal( ticket.last_contact_customer.to_s, article_inbound.created_at.to_s, 'ticket.last_contact_customer verify - note' )
    assert_equal( ticket.last_contact_agent, nil, 'ticket.last_contact_agent verify - note' )
    assert_equal( ticket.first_response, nil, 'ticket.first_response verify - note' )
    assert_equal( ticket.close_time, nil, 'ticket.close_time verify - note' )

    # create outbound article
    sleep 10
    article_outbound = Ticket::Article.create(
      :ticket_id              => ticket.id,
      :from                   => 'some_recipient@example.com',
      :to                     => 'some_sender@example.com',
      :subject                => 'some subject',
      :message_id             => 'some@id2',
      :body                   => 'some message 2',
      :internal               => false,
      :ticket_article_sender  => Ticket::Article::Sender.where(:name => 'Agent').first,
      :ticket_article_type    => Ticket::Article::Type.where(:name => 'email').first,
      :updated_by_id          => 1,
      :created_by_id          => 1,
    )

    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.article_count, 3, 'ticket.article_count verify - outbound' )
    assert_equal( ticket.last_contact.to_s, article_outbound.created_at.to_s, 'ticket.last_contact verify - outbound' )
    assert_equal( ticket.last_contact_customer.to_s, article_inbound.created_at.to_s, 'ticket.last_contact_customer verify - outbound' )
    assert_equal( ticket.last_contact_agent.to_s, article_outbound.created_at.to_s, 'ticket.last_contact_agent verify - outbound' )
    assert_equal( ticket.first_response.to_s, article_outbound.created_at.to_s, 'ticket.first_response verify - outbound' )
    assert_equal( ticket.close_time, nil, 'ticket.close_time verify - outbound' )

    ticket.ticket_state_id = Ticket::State.where(:name => 'closed').first.id
    ticket.save

    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.article_count, 3, 'ticket.article_count verify - state update' )
    assert_equal( ticket.last_contact.to_s, article_outbound.created_at.to_s, 'ticket.last_contact verify - state update' )
    assert_equal( ticket.last_contact_customer.to_s, article_inbound.created_at.to_s, 'ticket.last_contact_customer verify - state update' )
    assert_equal( ticket.last_contact_agent.to_s, article_outbound.created_at.to_s, 'ticket.last_contact_agent verify - state update' )
    assert_equal( ticket.first_response.to_s, article_outbound.created_at.to_s, 'ticket.first_response verify - state update' )
    assert( ticket.close_time, 'ticket.close_time verify - state update' )


    delete = ticket.destroy
    assert( delete, "ticket destroy" )
  end

  test 'ticket sla' do

    # cleanup
    delete = Sla.destroy_all
    assert( delete, "sla destroy_all" )
    delete = Ticket.destroy_all
    assert( delete, "ticket destroy_all" )

    ticket = Ticket.create(
      :title           => 'some title äöüß',
      :group           => Group.lookup( :name => 'Users'),
      :customer_id     => 2,
      :ticket_state    => Ticket::State.lookup( :name => 'new' ),
      :ticket_priority => Ticket::Priority.lookup( :name => '2 normal' ),
      :created_at      => '2013-03-21 09:30:00 UTC',
      :updated_at      => '2013-03-21 09:30:00 UTC',
      :updated_by_id   => 1,
      :created_by_id   => 1,
    )
    assert( ticket, "ticket created" )
    assert_equal( ticket.escalation_time, nil, 'ticket.escalation_time verify' )

    sla = Sla.create(
      :name => 'test sla 1',
      :condition => {},
      :data => {
        "Mon"=>"Mon", "Tue"=>"Tue", "Wed"=>"Wed", "Thu"=>"Thu", "Fri"=>"Fri", "Sat"=>"Sat", "Sun"=>"Sun",
        "beginning_of_workday" => "8:00",
        "end_of_workday"       => "18:00",
      },
      :first_response_time => 120,
      :update_time   => 180,
      :close_time    => 240,
      :active        => true,
      :updated_by_id => 1,
      :created_by_id => 1,
    )
    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.escalation_time verify 1' )
    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.first_response_escal_date verify 1' )
    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.update_time_escal_date verify 1' )
    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 13:30:00 UTC', 'ticket.close_time_escal_date verify 1' )
    delete = sla.destroy
    assert( delete, "sla destroy 1" )

    sla = Sla.create(
      :name => 'test sla 2',
      :condition => { "tickets.ticket_priority_id" =>["1", "2", "3"] },
      :data => {
        "Mon"=>"Mon", "Tue"=>"Tue", "Wed"=>"Wed", "Thu"=>"Thu", "Fri"=>"Fri", "Sat"=>"Sat", "Sun"=>"Sun",
        "beginning_of_workday" => "8:00",
        "end_of_workday"       => "18:00",
      },
      :first_response_time => 60,
      :update_time   => 120,
      :close_time    => 180,
      :active        => true,
      :updated_by_id => 1,
      :created_by_id => 1,
    )
    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.escalation_time verify 2' )
    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 2' )
    assert_equal( ticket.first_response, nil, 'ticket.first_response verify 2' )
    assert_equal( ticket.first_response_in_min, nil, 'ticket.first_response_in_min verify 2' )
    assert_equal( ticket.first_response_diff_in_min, nil, 'ticket.first_response_diff_in_min verify 2' )

    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.update_time_escal_date verify 2' )
    assert_equal( ticket.update_time_in_min, nil, 'ticket.update_time_in_min verify 2' )
    assert_equal( ticket.update_time_diff_in_min, nil, 'ticket.update_time_diff_in_min verify 2' )

    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.close_time_escal_date verify 2' )
    assert_equal( ticket.close_time_in_min, nil, 'ticket.close_time_in_min verify 2' )
    assert_equal( ticket.close_time_diff_in_min, nil, 'ticket.close_time_diff_in_min verify 2' )

    # set first response in time
    ticket.update_attributes(
      :first_response => '2013-03-21 10:00:00 UTC',
    )
    puts ticket.inspect

    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.escalation_time verify 3' )
    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 3' )
    assert_equal( ticket.first_response.gmtime.to_s, '2013-03-21 10:00:00 UTC', 'ticket.first_response verify 3' )
    assert_equal( ticket.first_response_in_min, 30, 'ticket.first_response_in_min verify 3' )
    assert_equal( ticket.first_response_diff_in_min, 30, 'ticket.first_response_diff_in_min verify 3' )

    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.update_time_escal_date verify 3' )
    assert_equal( ticket.update_time_in_min, nil, 'ticket.update_time_in_min verify 3' )
    assert_equal( ticket.update_time_diff_in_min, nil, 'ticket.update_time_diff_in_min verify 3' )

    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.close_time_escal_date verify 3' )
    assert_equal( ticket.close_time_in_min, nil, 'ticket.close_time_in_min verify 3' )
    assert_equal( ticket.close_time_diff_in_min, nil, 'ticket.close_time_diff_in_min verify 3' )
 
    # set first reponse over time
    ticket.update_attributes(
      :first_response => '2013-03-21 14:00:00 UTC',
    )
    puts ticket.inspect

    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.escalation_time verify 4' )
    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 4' )
    assert_equal( ticket.first_response.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.first_response verify 4' )
    assert_equal( ticket.first_response_in_min, 270, 'ticket.first_response_in_min verify 4' )
    assert_equal( ticket.first_response_diff_in_min, -210, 'ticket.first_response_diff_in_min verify 4' )

    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.update_time_escal_date verify 4' )
    assert_equal( ticket.update_time_in_min, nil, 'ticket.update_time_in_min verify 4' )
    assert_equal( ticket.update_time_diff_in_min, nil, 'ticket.update_time_diff_in_min verify 4' )

    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.close_time_escal_date verify 4' )
    assert_equal( ticket.close_time_in_min, nil, 'ticket.close_time_in_min verify 4' )
    assert_equal( ticket.close_time_diff_in_min, nil, 'ticket.close_time_diff_in_min verify 4' ) 

    # set update time in time
    ticket.update_attributes(
      :last_contact_agent => '2013-03-21 11:00:00 UTC',
    )
    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.escalation_time verify 5' )

    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 5' )
    assert_equal( ticket.first_response.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.first_response verify 5' )
    assert_equal( ticket.first_response_in_min, 270, 'ticket.first_response_in_min verify 5' )
    assert_equal( ticket.first_response_diff_in_min, -210, 'ticket.first_response_diff_in_min verify 5' )

    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 13:00:00 UTC', 'ticket.update_time_escal_date verify 5' )
    assert_equal( ticket.update_time_in_min, 90, 'ticket.update_time_in_min verify 5' )
    assert_equal( ticket.update_time_diff_in_min, 30, 'ticket.update_time_diff_in_min verify 5' )

    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.close_time_escal_date verify 5' )
    assert_equal( ticket.close_time_in_min, nil, 'ticket.close_time_in_min verify 5' )
    assert_equal( ticket.close_time_diff_in_min, nil, 'ticket.close_time_diff_in_min verify 5' )

    # set update time over time
    ticket.update_attributes(
      :last_contact_agent => '2013-03-21 12:00:00 UTC',
    )
    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.escalation_time verify 6' )

    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 6' )
    assert_equal( ticket.first_response.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.first_response verify 6' )
    assert_equal( ticket.first_response_in_min, 270, 'ticket.first_response_in_min verify 6' )
    assert_equal( ticket.first_response_diff_in_min, -210, 'ticket.first_response_diff_in_min verify 6' )

    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.update_time_escal_date verify 6' )
    assert_equal( ticket.update_time_in_min, 150, 'ticket.update_time_in_min verify 6' )
    assert_equal( ticket.update_time_diff_in_min, -30, 'ticket.update_time_diff_in_min verify 6' )

    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.close_time_escal_date verify 6' )
    assert_equal( ticket.close_time_in_min, nil, 'ticket.close_time_in_min verify 6' )
    assert_equal( ticket.close_time_diff_in_min, nil, 'ticket.close_time_diff_in_min verify 6' )

    # set close time in time
    ticket.update_attributes(
      :close_time   => '2013-03-21 11:30:00 UTC',
    )
    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.escalation_time verify 7' )

    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 7' )
    assert_equal( ticket.first_response.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.first_response verify 7' )
    assert_equal( ticket.first_response_in_min, 270, 'ticket.first_response_in_min verify 7' )
    assert_equal( ticket.first_response_diff_in_min, -210, 'ticket.first_response_diff_in_min verify 7' )

    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.update_time_escal_date verify 7' )
    assert_equal( ticket.update_time_in_min, 150, 'ticket.update_time_in_min verify 7' )
    assert_equal( ticket.update_time_diff_in_min, -30, 'ticket.update_time_diff_in_min verify 7' )

    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.close_time_escal_date verify 7' )
    assert_equal( ticket.close_time_in_min, 120, 'ticket.close_time_in_min verify 7' )
    assert_equal( ticket.close_time_diff_in_min, 60, 'ticket.close_time_diff_in_min verify 7' )

    # set close time over time
    ticket.update_attributes(
      :close_time   => '2013-03-21 13:00:00 UTC',
    )
    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.escalation_time verify 8' )

    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 8' )
    assert_equal( ticket.first_response.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.first_response verify 8' )
    assert_equal( ticket.first_response_in_min, 270, 'ticket.first_response_in_min verify 8' )
    assert_equal( ticket.first_response_diff_in_min, -210, 'ticket.first_response_diff_in_min verify 8' )

    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.update_time_escal_date verify 8' )
    assert_equal( ticket.update_time_in_min, 150, 'ticket.update_time_in_min verify 8' )
    assert_equal( ticket.update_time_diff_in_min, -30, 'ticket.update_time_diff_in_min verify 8' )

    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.close_time_escal_date verify 8' )
    assert_equal( ticket.close_time_in_min, 210, 'ticket.close_time_in_min verify 8' )
    assert_equal( ticket.close_time_diff_in_min, -30, 'ticket.close_time_diff_in_min verify 8' )

    # set close time over time
    ticket.update_attributes(
      :ticket_state => Ticket::State.lookup( :name => 'closed' )
    )
    assert_equal( ticket.escalation_time, nil, 'ticket.escalation_time verify 9' )

    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 9' )
    assert_equal( ticket.first_response.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.first_response verify 9' )
    assert_equal( ticket.first_response_in_min, 270, 'ticket.first_response_in_min verify 9' )
    assert_equal( ticket.first_response_diff_in_min, -210, 'ticket.first_response_diff_in_min verify 9' )

    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.update_time_escal_date verify 9' )
    assert_equal( ticket.update_time_in_min, 150, 'ticket.update_time_in_min verify 9' )
    assert_equal( ticket.update_time_diff_in_min, -30, 'ticket.update_time_diff_in_min verify 9' )

    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.close_time_escal_date verify 9' )
    assert_equal( ticket.close_time_in_min, 210, 'ticket.close_time_in_min verify 9' )
    assert_equal( ticket.close_time_diff_in_min, -30, 'ticket.close_time_diff_in_min verify 9' )

    delete = ticket.destroy
    assert( delete, "ticket destroy" )

    ticket = Ticket.create(
      :title           => 'some title äöüß',
      :group           => Group.lookup( :name => 'Users'),
      :customer_id     => 2,
      :ticket_state    => Ticket::State.lookup( :name => 'new' ),
      :ticket_priority => Ticket::Priority.lookup( :name => '2 normal' ),
      :updated_by_id   => 1,
      :created_by_id   => 1,
      :created_at      => '2013-03-28 23:49:00 UTC',
      :updated_at      => '2013-03-28 23:49:00 UTC',
    )
    assert( ticket, "ticket created" )

    assert_equal( ticket.title, 'some title äöüß', 'ticket.title verify' )
    assert_equal( ticket.group.name, 'Users', 'ticket.group verify' )
    assert_equal( ticket.ticket_state.name, 'new', 'ticket.state verify' )

    # create inbound article
    article_inbound = Ticket::Article.create(
      :ticket_id              => ticket.id,
      :from                   => 'some_sender@example.com',
      :to                     => 'some_recipient@example.com',
      :subject                => 'some subject',
      :message_id             => 'some@id',
      :body                   => 'some message',
      :internal               => false,
      :ticket_article_sender  => Ticket::Article::Sender.where(:name => 'Customer').first,
      :ticket_article_type    => Ticket::Article::Type.where(:name => 'email').first,
      :updated_by_id          => 1,
      :created_by_id          => 1,
      :created_at             => '2013-03-28 23:49:00 UTC',
      :updated_at             => '2013-03-28 23:49:00 UTC',
    )
    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.article_count, 1, 'ticket.article_count verify - inbound' )
    assert_equal( ticket.last_contact.to_s, article_inbound.created_at.to_s, 'ticket.last_contact verify - inbound' )
    assert_equal( ticket.last_contact_customer.to_s, article_inbound.created_at.to_s, 'ticket.last_contact_customer verify - inbound' )
    assert_equal( ticket.last_contact_agent, nil, 'ticket.last_contact_agent verify - inbound' )
    assert_equal( ticket.first_response, nil, 'ticket.first_response verify - inbound' )
    assert_equal( ticket.close_time, nil, 'ticket.close_time verify - inbound' )

    # create outbound article
    article_outbound = Ticket::Article.create(
      :ticket_id              => ticket.id,
      :from                   => 'some_recipient@example.com',
      :to                     => 'some_sender@example.com',
      :subject                => 'some subject',
      :message_id             => 'some@id2',
      :body                   => 'some message 2',
      :internal               => false,
      :ticket_article_sender  => Ticket::Article::Sender.where(:name => 'Agent').first,
      :ticket_article_type    => Ticket::Article::Type.where(:name => 'email').first,
      :updated_by_id          => 1,
      :created_by_id          => 1,
      :created_at             => '2013-03-29 08:00:03 UTC',
      :updated_at             => '2013-03-29 08:00:03 UTC',
    )

    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.article_count, 2, 'ticket.article_count verify - outbound' )
    assert_equal( ticket.last_contact.to_s, article_outbound.created_at.to_s, 'ticket.last_contact verify - outbound' )
    assert_equal( ticket.last_contact_customer.to_s, article_inbound.created_at.to_s, 'ticket.last_contact_customer verify - outbound' )
    assert_equal( ticket.last_contact_agent.to_s, article_outbound.created_at.to_s, 'ticket.last_contact_agent verify - outbound' )
    assert_equal( ticket.first_response.to_s, article_outbound.created_at.to_s, 'ticket.first_response verify - outbound' )
    assert_equal( ticket.first_response_in_min, 0, 'ticket.first_response_in_min verify - outbound' )
    assert_equal( ticket.first_response_diff_in_min, 60, 'ticket.first_response_diff_in_min verify - outbound' )
    assert_equal( ticket.close_time, nil, 'ticket.close_time verify - outbound' )


    delete = ticket.destroy
    assert( delete, "ticket destroy" )


    delete = sla.destroy
    assert( delete, "sla destroy" )

    delete = sla.destroy
    assert( delete, "sla destroy" )
  end
end