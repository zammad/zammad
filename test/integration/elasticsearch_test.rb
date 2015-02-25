# encoding: utf-8
require 'integration_test_helper'

class ElasticSearchTest < ActiveSupport::TestCase

  Setting.set('es_url', 'http://172.0.0.1:9200')
  Setting.set('es_index', 'estest.local_zammad')
  #Setting.set('es_user', 'elasticsearch')
  #Setting.set('es_password', 'zammad')

  # drop/create indexes
  Rake::Task["searchindex:drop"].execute
  Rake::Task["searchindex:create"].execute

  groups = Group.where( :name => 'Users' )
  roles  = Role.where( :name => 'Agent' )
  agent  = User.create_or_update(
    :login         => 'es-agent@example.com',
    :firstname     => 'E',
    :lastname      => 'S',
    :email         => 'es-agent@example.com',
    :password      => 'agentpw',
    :active        => true,
    :roles         => roles,
    :groups        => groups,
    :updated_by_id => 1,
    :created_by_id => 1,
  )
  group_without_access = Group.create_if_not_exists(
    :name          => 'WithoutAccess',
    :note          => 'Test for not access check.',
    :updated_by_id => 1,
    :created_by_id => 1
  )


  # check tickets and search it
  test 'tickets' do

    ticket1 = Ticket.create(
      :title         => "some title\n äöüß",
      :group         => Group.lookup( :name => 'Users'),
      :customer_id   => 2,
      :state         => Ticket::State.lookup( :name => 'new' ),
      :priority      => Ticket::Priority.lookup( :name => '2 normal' ),
      :updated_by_id => 1,
      :created_by_id => 1,
    )
    article = Ticket::Article.create(
      :ticket_id     => ticket1.id,
      :from          => 'some_sender@example.com',
      :to            => 'some_recipient@example.com',
      :subject       => 'some subject',
      :message_id    => 'some@id',
      :body          => 'some message',
      :internal      => false,
      :sender        => Ticket::Article::Sender.where(:name => 'Customer').first,
      :type          => Ticket::Article::Type.where(:name => 'email').first,
      :updated_by_id => 1,
      :created_by_id => 1,
    )
    ticket1.search_index_update_backend

    ticket2 = Ticket.create(
      :title         => "something else",
      :group         => Group.lookup( :name => 'Users'),
      :customer_id   => 2,
      :state         => Ticket::State.lookup( :name => 'open' ),
      :priority      => Ticket::Priority.lookup( :name => '2 normal' ),
      :updated_by_id => 1,
      :created_by_id => 1,
    )
    article = Ticket::Article.create(
      :ticket_id     => ticket2.id,
      :from          => 'some_sender@example.org',
      :to            => 'some_recipient@example.org',
      :subject       => 'some subject2',
      :message_id    => 'some@id',
      :body          => 'some other message',
      :internal      => false,
      :sender        => Ticket::Article::Sender.where(:name => 'Customer').first,
      :type          => Ticket::Article::Type.where(:name => 'email').first,
      :updated_by_id => 1,
      :created_by_id => 1,
    )
    ticket2.search_index_update_backend

    ticket3 = Ticket.create(
      :title         => "something else",
      :group         => Group.lookup( :name => 'Users'),
      :customer_id   => 2,
      :state         => Ticket::State.lookup( :name => 'open' ),
      :priority      => Ticket::Priority.lookup( :name => '2 normal' ),
      :updated_by_id => 1,
      :created_by_id => 1,
    )
    article = Ticket::Article.create(
      :ticket_id     => ticket3.id,
      :from          => 'some_sender@example.org',
      :to            => 'some_recipient@example.org',
      :subject       => 'some subject3',
      :message_id    => 'some@id',
      :body          => 'some other message 3',
      :internal      => false,
      :sender        => Ticket::Article::Sender.where(:name => 'Customer').first,
      :type          => Ticket::Article::Type.where(:name => 'email').first,
      :updated_by_id => 1,
      :created_by_id => 1,
    )
    ticket3.search_index_update_backend


    result = Ticket.search(
      :current_user => agent,
      :query        => 'subject2',
      :limit        => 15,
    )
    puts "RRR #{result.inspect}"
    assert_equal( 24, Group.count, 'groups' )

  end
end