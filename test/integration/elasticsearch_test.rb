# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class ElasticsearchTest < ActiveSupport::TestCase
  include SearchindexHelper

  setup do

    configure_elasticsearch(required: true)

    rebuild_searchindex

    groups = Group.where(name: 'Users')
    roles  = Role.where(name: 'Agent')
    @agent = User.create!(
      login:         'es-agent@example.com',
      firstname:     'E',
      lastname:      'S',
      email:         'es-agent@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        groups,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Group.create_if_not_exists(
      name:          'WithoutAccess',
      note:          'Test for not access check.',
      updated_by_id: 1,
      created_by_id: 1
    )
    roles = Role.where(name: 'Customer')
    @organization1 = Organization.create_if_not_exists(
      name:          'Customer Organization Update',
      note:          'some note',
      updated_by_id: 1,
      created_by_id: 1,
    )
    @customer1 = User.create!(
      login:           'es-customer1@example.com',
      firstname:       'ES',
      lastname:        'Customer1',
      email:           'es-customer1@example.com',
      password:        'customerpw',
      active:          true,
      organization_id: @organization1.id,
      roles:           roles,
      updated_by_id:   1,
      created_by_id:   1,
    )
    @customer2 = User.create!(
      login:           'es-customer2@example.com',
      firstname:       'ES',
      lastname:        'Customer2',
      email:           'es-customer2@example.com',
      password:        'customerpw',
      active:          true,
      organization_id: @organization1.id,
      roles:           roles,
      updated_by_id:   1,
      created_by_id:   1,
    )
    @customer3 = User.create!(
      login:         'es-customer3@example.com',
      firstname:     'ES',
      lastname:      'Customer3',
      email:         'es-customer3@example.com',
      password:      'customerpw',
      active:        true,
      roles:         roles,
      updated_by_id: 1,
      created_by_id: 1,
    )

    # execute background jobs to index created/changed objects
    Scheduler.worker(true)
    SearchIndexBackend.refresh

  end

  # check search attributes
  test 'a - objects' do

    # user
    attributes = @agent.search_index_attribute_lookup
    assert_equal('E', attributes['firstname'])
    assert_equal('S', attributes['lastname'])
    assert_equal('es-agent@example.com', attributes['email'])
    assert(attributes['preferences'])
    assert_not(attributes['password'])
    assert_not(attributes['organization'])

    attributes = @customer1.search_index_attribute_lookup
    assert_equal('ES', attributes['firstname'])
    assert_equal('Customer1', attributes['lastname'])
    assert_equal('es-customer1@example.com', attributes['email'])
    assert(attributes['preferences'])
    assert_not(attributes['password'])
    assert_equal('Customer Organization Update', attributes['organization']['name'])

    # organization
    attributes = @organization1.search_index_attribute_lookup
    assert_equal('Customer Organization Update', attributes['name'])
    assert_equal('some note', attributes['note'])
    assert(attributes['members'])

    # ticket/article
    ticket1 = Ticket.create!(
      title:         'some title äöüß',
      group:         Group.lookup(name: 'Users'),
      customer_id:   @customer1.id,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    article1 = Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.where(name: 'Customer').first,
      type:          Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Store.add(
      object:        'Ticket::Article',
      o_id:          article1.id,
      data:          File.binread(Rails.root.join('test/data/elasticsearch/es-normal.txt')),
      filename:      'es-normal.txt',
      preferences:   {},
      created_by_id: 1,
    )

    attributes = ticket1.search_index_attribute_lookup
    assert_equal('Users', attributes['group']['name'])
    assert_equal('new', attributes['state']['name'])
    assert_equal('2 normal', attributes['priority']['name'])

    assert_equal('ES', attributes['customer']['firstname'])
    assert_equal('Customer1', attributes['customer']['lastname'])
    assert_equal('es-customer1@example.com', attributes['customer']['email'])
    assert_not(attributes['customer']['password'])
    assert_nil(attributes['customer']['organization'])

    assert_equal('-', attributes['owner']['login'])
    assert_equal('-', attributes['owner']['firstname'])
    assert_not(attributes['owner']['password'])
    assert_not(attributes['owner']['organization'])

    assert(attributes['article'][0]['attachment'])
    assert(attributes['article'][0]['attachment'][0])
    assert_not(attributes['article'][0]['attachment'][1])
    assert_equal('es-normal.txt', attributes['article'][0]['attachment'][0]['_name'])
    assert_equal('c29tZSBub3JtYWwgdGV4dDY2Cg==', attributes['article'][0]['attachment'][0]['_content'])

    ticket1.destroy!

    # execute background jobs
    Scheduler.worker(true)
    SearchIndexBackend.refresh

    ticket1 = Ticket.create!(
      title:         "some title\n äöüß",
      group:         Group.lookup(name: 'Users'),
      customer_id:   @customer1.id,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    article1 = Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.where(name: 'Customer').first,
      type:          Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: 1,
      created_by_id: 1,
    )

    # add attachments which should get index / .txt
    # "some normal text66"
    Store.add(
      object:        'Ticket::Article',
      o_id:          article1.id,
      data:          File.binread(Rails.root.join('test/data/elasticsearch/es-normal.txt')),
      filename:      'es-normal.txt',
      preferences:   {},
      created_by_id: 1,
    )

    # add attachments which should get index / .pdf
    # "Zammad Test77"
    Store.add(
      object:        'Ticket::Article',
      o_id:          article1.id,
      data:          File.binread(Rails.root.join('test/data/elasticsearch/es-pdf1.pdf')),
      filename:      'es-pdf1.pdf',
      preferences:   {},
      created_by_id: 1,
    )

    # add attachments which should get index / .box
    # "Old programmers never die test99"
    Store.add(
      object:        'Ticket::Article',
      o_id:          article1.id,
      data:          File.binread(Rails.root.join('test/data/elasticsearch/es-box1.box')),
      filename:      'mail1.box',
      preferences:   {},
      created_by_id: 1,
    )

    # add to big attachment which should not get index
    # "some too big text88"
    Store.add(
      object:        'Ticket::Article',
      o_id:          article1.id,
      data:          File.binread(Rails.root.join('test/data/elasticsearch/es-too-big.txt')),
      filename:      'es-too-big.txt',
      preferences:   {},
      created_by_id: 1,
    )
    ticket1.tag_add('someTagA', 1)
    travel 1.minute

    ticket2 = Ticket.create!(
      title:         'something else',
      group:         Group.lookup(name: 'Users'),
      customer_id:   @customer2.id,
      state:         Ticket::State.lookup(name: 'open'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id:     ticket2.id,
      from:          'some_sender@example.org',
      to:            'some_recipient@example.org',
      subject:       'some subject2 / autobahn what else?',
      message_id:    'some@id',
      body:          'some other message <b>with s<u>t</u>rong text<b>',
      content_type:  'text/html',
      internal:      false,
      sender:        Ticket::Article::Sender.where(name: 'Customer').first,
      type:          Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket2.tag_add('someTagB', 1)
    travel 1.minute

    ticket3 = Ticket.create!(
      title:         'something else',
      group:         Group.lookup(name: 'WithoutAccess'),
      customer_id:   @customer3.id,
      state:         Ticket::State.lookup(name: 'open'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id:     ticket3.id,
      from:          'some_sender@example.org',
      to:            'some_recipient@example.org',
      subject:       'some subject3',
      message_id:    'some@id',
      body:          'some other message 3 / kindergarden what else?',
      internal:      false,
      sender:        Ticket::Article::Sender.where(name: 'Customer').first,
      type:          Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: 1,
      created_by_id: 1,
    )

    # execute background jobs
    Scheduler.worker(true)
    SearchIndexBackend.refresh

    # search as @agent

    # search for article data
    result = Ticket.search(
      current_user: @agent,
      query:        'autobahn',
      limit:        15,
    )

    assert(result.present?, 'result exists not')
    assert(result[0], 'record 1')
    assert_not(result[1], 'record 2')
    assert_equal(result[0].id, ticket2.id)

    # search for html content
    result = Ticket.search(
      current_user: @agent,
      query:        'strong',
      limit:        15,
    )

    assert(result.present?, 'result exists not')
    assert(result[0], 'record 1')
    assert_not(result[1], 'record 2')
    assert_equal(result[0].id, ticket2.id)

    # search for indexed attachment
    result = Ticket.search(
      current_user: @agent,
      query:        '"some normal text66"',
      limit:        15,
    )
    assert(result[0], 'record 1')
    assert_equal(result[0].id, ticket1.id)

    result = Ticket.search(
      current_user: @agent,
      query:        'test77',
      limit:        15,
    )
    assert(result[0], 'record 1')
    assert_equal(result[0].id, ticket1.id)

    # search for not indexed attachment
    result = Ticket.search(
      current_user: @agent,
      query:        'test88',
      limit:        15,
    )
    assert_not(result[0], 'record 1')

    result = Ticket.search(
      current_user: @agent,
      query:        'test99',
      limit:        15,
    )
    assert_not(result[0], 'record 1')

    # search for ticket with no permissions
    result = Ticket.search(
      current_user: @agent,
      query:        'kindergarden',
      limit:        15,
    )
    assert(result.blank?, 'result should be empty')
    assert_not(result[0], 'record 1')

    # search as @customer1
    result = Ticket.search(
      current_user: @customer1,
      query:        'title OR else',
      limit:        15,
    )

    assert(result.present?, 'result exists not')
    assert(result[0], 'record 1')
    assert(result[1], 'record 2')
    assert_not(result[2], 'record 3')
    assert_equal(result[0].id, ticket2.id)
    assert_equal(result[1].id, ticket1.id)

    # search as @customer2
    result = Ticket.search(
      current_user: @customer2,
      query:        'title OR else',
      limit:        15,
    )

    assert(result.present?, 'result exists not')
    assert(result[0], 'record 1')
    assert(result[1], 'record 2')
    assert_not(result[2], 'record 3')
    assert_equal(result[0].id, ticket2.id)
    assert_equal(result[1].id, ticket1.id)

    # search as @customer3
    result = Ticket.search(
      current_user: @customer3,
      query:        'title OR else',
      limit:        15,
    )

    assert(result.present?, 'result exists not')
    assert(result[0], 'record 1')
    assert_not(result[1], 'record 2')
    assert_equal(result[0].id, ticket3.id)

    # search for tags
    result = Ticket.search(
      current_user: @agent,
      query:        'tags:someTagA',
      limit:        15,
    )
    assert(result[0], 'record 1')
    assert_not(result[1], 'record 1')
    assert_equal(result[0].id, ticket1.id)

    result = Ticket.search(
      current_user: @agent,
      query:        'tags:someTagB',
      limit:        15,
    )
    assert(result[0], 'record 2')
    assert_not(result[1], 'record 2')
    assert_equal(result[0].id, ticket2.id)

    # rename tag (e. g. via admin interface)
    tag_item = Tag::Item.lookup(name: 'someTagA')
    Tag::Item.rename(
      id:            tag_item.id,
      name:          'someTagC',
      updated_by_id: 1,
    )

    # execute background jobs
    Scheduler.worker(true)
    SearchIndexBackend.refresh

    # search for tags
    result = Ticket.search(
      current_user: @agent,
      query:        'tags:someTagA',
      limit:        15,
    )
    assert_not(result[0], 'record 1')
    assert_not(result[1], 'record 1')

    result = Ticket.search(
      current_user: @agent,
      query:        'tags:someTagB',
      limit:        15,
    )
    assert(result[0], 'record 2')
    assert_not(result[1], 'record 2')
    assert_equal(result[0].id, ticket2.id)

    result = Ticket.search(
      current_user: @agent,
      query:        'tags:someTagC',
      limit:        15,
    )
    assert(result[0], 'record 1')
    assert_not(result[1], 'record 2')
    assert_equal(result[0].id, ticket1.id)

    result = Ticket.search(
      current_user: @agent,
      query:        'state.name:open',
      limit:        15,
    )
    assert(result[0], 'record 1')
    assert_not(result[1], 'record 2')
    assert_equal(result[0].id, ticket2.id)

    result = Ticket.search(
      current_user: @agent,
      query:        '"some_sender@example.com"',
      limit:        15,
    )
    assert(result[0], 'record 1')
    assert_not(result[1], 'record 2')
    assert_equal(result[0].id, ticket1.id)

    result = Ticket.search(
      current_user: @agent,
      query:        'article.from:"some_sender@example.com"',
      limit:        15,
    )
    assert(result[0], 'record 1')
    assert_not(result[1], 'record 2')
    assert_equal(result[0].id, ticket1.id)

    # check users and search it
    # search as @agent
    result = User.search(
      current_user: @agent,
      query:        'customer1',
      limit:        15,
    )
    assert(result.present?, 'result should not be empty')
    assert(result[0], 'record 1')
    assert_not(result[1], 'record 2')
    assert_equal(result[0].id, @customer1.id)

    # search as @customer1
    result = User.search(
      current_user: @customer1,
      query:        'customer1',
      limit:        15,
    )
    assert(result.blank?, 'result should be empty')
    assert_not(result[0], 'record 1')

    # cleanup
    Rake::Task['searchindex:drop'].execute
  end

end
