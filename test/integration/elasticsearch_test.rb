# encoding: utf-8
require 'integration_test_helper'

class ElasticsearchTest < ActiveSupport::TestCase

  # set config
  # Setting.set('es_url', 'http://172.0.0.1:9200')
  Setting.set('es_url', 'http://10.240.2.11:9200')
  Setting.set('es_index', 'estest.local_zammad')
  # Setting.set('es_user', 'elasticsearch')
  # Setting.set('es_password', 'zammad')

  # set max attachment size

  # set attachment types

  # drop/create indexes
  #Rake::Task["searchindex:drop"].execute
  #Rake::Task["searchindex:create"].execute
  system('rake searchindex:rebuild')

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
  roles  = Role.where( :name => 'Customer' )
  organization1 = Organization.create_if_not_exists(
    :name          => 'Customer Organization Update',
    :updated_by_id => 1,
    :created_by_id => 1,
  )
  customer1 = User.create_or_update(
    :login           => 'es-customer1@example.com',
    :firstname       => 'ES',
    :lastname        => 'Customer1',
    :email           => 'es-customer1@example.com',
    :password        => 'customerpw',
    :active          => true,
    :organization_id => organization1.id,
    :roles           => roles,
    :updated_by_id   => 1,
    :created_by_id   => 1,
  )
  sleep 1
  customer2 = User.create_or_update(
    :login           => 'es-customer2@example.com',
    :firstname       => 'ES',
    :lastname        => 'Customer2',
    :email           => 'es-customer2@example.com',
    :password        => 'customerpw',
    :active          => true,
    :organization_id => organization1.id,
    :roles           => roles,
    :updated_by_id   => 1,
    :created_by_id   => 1,
  )
  sleep 1
  customer3 = User.create_or_update(
    :login           => 'es-customer3@example.com',
    :firstname       => 'ES',
    :lastname        => 'Customer3',
    :email           => 'es-customer3@example.com',
    :password        => 'customerpw',
    :active          => true,
    :roles           => roles,
    :updated_by_id   => 1,
    :created_by_id   => 1,
  )

  # check tickets and search it
  test 'a - tickets' do

    ticket1 = Ticket.create(
      :title         => "some title\n äöüß",
      :group         => Group.lookup( :name => 'Users'),
      :customer_id   => customer1.id,
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
    sleep 1

    ticket2 = Ticket.create(
      :title         => "something else",
      :group         => Group.lookup( :name => 'Users'),
      :customer_id   => customer2.id,
      :state         => Ticket::State.lookup( :name => 'open' ),
      :priority      => Ticket::Priority.lookup( :name => '2 normal' ),
      :updated_by_id => 1,
      :created_by_id => 1,
    )
    article = Ticket::Article.create(
      :ticket_id     => ticket2.id,
      :from          => 'some_sender@example.org',
      :to            => 'some_recipient@example.org',
      :subject       => 'some subject2 / autobahn what else?',
      :message_id    => 'some@id',
      :body          => 'some other message <b>with s<u>t</u>rong text<b>',
      :content_type  => 'text/html',
      :internal      => false,
      :sender        => Ticket::Article::Sender.where(:name => 'Customer').first,
      :type          => Ticket::Article::Type.where(:name => 'email').first,
      :updated_by_id => 1,
      :created_by_id => 1,
    )

    # add attachments which should get index

    # add attachments which should not get index

    # add to big attachment which should not get index



    sleep 1

    ticket3 = Ticket.create(
      :title         => "something else",
      :group         => Group.lookup( :name => 'WithoutAccess'),
      :customer_id   => customer3.id,
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
      :body          => 'some other message 3 / kindergarden what else?',
      :internal      => false,
      :sender        => Ticket::Article::Sender.where(:name => 'Customer').first,
      :type          => Ticket::Article::Type.where(:name => 'email').first,
      :updated_by_id => 1,
      :created_by_id => 1,
    )

    # execute background jobs
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off

    sleep 6

    # search as agent

    # search for article data
    result = Ticket.search(
      :current_user => agent,
      :query        => 'autobahn',
      :limit        => 15,
    )

    assert(!result.empty?, 'result exists not')
    assert(result[0], 'record 1')
    assert(!result[1], 'record 2')
    assert_equal(result[0].id, ticket2.id)

    # search for html content
    result = Ticket.search(
      :current_user => agent,
      :query        => 'strong',
      :limit        => 15,
    )

    assert(!result.empty?, 'result exists not')
    assert(result[0], 'record 1')
    assert(!result[1], 'record 2')
    assert_equal(result[0].id, ticket2.id)

    # search for indexed attachment

    # search for not indexed attachment



    # search for ticket with no permissions
    result = Ticket.search(
      :current_user => agent,
      :query        => 'kindergarden',
      :limit        => 15,
    )
    assert(result.empty?, 'result should be empty')
    assert(!result[0], 'record 1')


    # search as customer1
    result = Ticket.search(
      :current_user => customer1,
      :query        => 'title OR else',
      :limit        => 15,
    )

    assert(!result.empty?, 'result exists not')
    assert(result[0], 'record 1')
    assert(result[1], 'record 2')
    assert(!result[2], 'record 3')
    assert_equal(result[0].id, ticket2.id)
    assert_equal(result[1].id, ticket1.id)

    # search as customer2
    result = Ticket.search(
      :current_user => customer2,
      :query        => 'title OR else',
      :limit        => 15,
    )

    assert(!result.empty?, 'result exists not')
    assert(result[0], 'record 1')
    assert(result[1], 'record 2')
    assert(!result[2], 'record 3')
    assert_equal(result[0].id, ticket2.id)
    assert_equal(result[1].id, ticket1.id)

    # search as customer3
    result = Ticket.search(
      :current_user => customer3,
      :query        => 'title OR else',
      :limit        => 15,
    )

    assert(!result.empty?, 'result exists not')
    assert(result[0], 'record 1')
    assert(!result[1], 'record 2')
    assert_equal(result[0].id, ticket3.id)
  end

  # check users and search it
  test 'b - users' do

    # search as agent
    result = User.search(
      :current_user => agent,
      :query        => 'customer1',
      :limit        => 15,
    )
    assert(!result.empty?, 'result should not be empty')
    assert(result[0], 'record 1')
    assert(!result[1], 'record 2')
    assert_equal(result[0].id, customer1.id)

    # search as customer1
    result = User.search(
      :current_user => customer1,
      :query        => 'customer1',
      :limit        => 15,
    )
    assert(result.empty?, 'result should be empty')
    assert(!result[0], 'record 1')

  end
end