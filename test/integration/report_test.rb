# encoding: utf-8
require 'integration_test_helper'
require 'rake'

class ReportTest < ActiveSupport::TestCase

  setup do

    # set config
    if ENV['ES_URL'].blank?
      raise "ERROR: Need ES_URL - hint ES_URL='http://127.0.0.1:9200'"
    end
    Setting.set('es_url', ENV['ES_URL'])
    if ENV['ES_INDEX_RAND'].present?
      ENV['ES_INDEX'] = "es_index_#{rand(999_999_999)}"
    end
    if ENV['ES_INDEX'].blank?
      raise "ERROR: Need ES_INDEX - hint ES_INDEX='estest.local_zammad'"
    end

    # Setting.set('es_url', 'http://127.0.0.1:9200')
    # Setting.set('es_index', 'estest.local_zammad')
    # Setting.set('es_user', 'elasticsearch')
    # Setting.set('es_password', 'zammad')
    # Setting.set('es_attachment_max_size_in_mb', 1)

    Ticket.destroy_all

    # drop/create indexes
    Rake::Task.clear
    Zammad::Application.load_tasks
    #Rake::Task["searchindex:drop"].execute
    #Rake::Task["searchindex:create"].execute
    Rake::Task['searchindex:rebuild'].execute

    group1 = Group.lookup(name: 'Users')
    group2 = Group.create_if_not_exists(
      name: 'Report Test',
      updated_by_id: 1,
      created_by_id: 1
    )

    @ticket1 = Ticket.create!(
      title: 'test 1',
      group: group2,
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      created_at: '2015-10-28 09:30:00 UTC',
      updated_at: '2015-10-28 09:30:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: @ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message article_inbound',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Customer').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      created_at: '2015-10-28 09:30:00 UTC',
      updated_at: '2015-10-28 09:30:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )
    @ticket1.update_attributes(
      group: Group.lookup(name: 'Users'),
      updated_at: '2015-10-28 14:30:00 UTC',
    )

    @ticket2 = Ticket.create!(
      title: 'test 2',
      group: group1,
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      created_at: '2015-10-28 09:30:01 UTC',
      updated_at: '2015-10-28 09:30:01 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: @ticket2.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message article_inbound',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Customer').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      created_at: '2015-10-28 09:30:01 UTC',
      updated_at: '2015-10-28 09:30:01 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )
    @ticket2.update_attributes(
      group_id: group2.id,
      updated_at: '2015-10-28 14:30:00 UTC',
    )

    @ticket3 = Ticket.create!(
      title: 'test 3',
      group: group1,
      customer_id: 2,
      state: Ticket::State.lookup(name: 'open'),
      priority: Ticket::Priority.lookup(name: '3 high'),
      created_at: '2015-10-28 10:30:00 UTC',
      updated_at: '2015-10-28 10:30:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: @ticket3.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message article_inbound',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Customer').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      created_at: '2015-10-28 10:30:00 UTC',
      updated_at: '2015-10-28 10:30:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )

    @ticket4 = Ticket.create!(
      title: 'test 4',
      group: group1,
      customer_id: 2,
      state: Ticket::State.lookup(name: 'closed'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      close_at: '2015-10-28 11:30:00 UTC',
      created_at: '2015-10-28 10:30:00 UTC',
      updated_at: '2015-10-28 10:30:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: @ticket4.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message article_inbound',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Customer').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      created_at: '2015-10-28 10:30:00 UTC',
      updated_at: '2015-10-28 10:30:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )

    @ticket5 = Ticket.create!(
      title: 'test 5',
      group: group1,
      customer_id: 2,
      state: Ticket::State.lookup(name: 'closed'),
      priority: Ticket::Priority.lookup(name: '3 high'),
      close_at: '2015-10-28 11:40:00 UTC',
      created_at: '2015-10-28 11:30:00 UTC',
      updated_at: '2015-10-28 11:30:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: @ticket5.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message article_outbound',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Agent').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      created_at: '2015-10-28 11:30:00 UTC',
      updated_at: '2015-10-28 11:30:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )
    @ticket5.update_attributes(
      state: Ticket::State.lookup(name: 'open'),
      updated_at: '2015-10-28 14:30:00 UTC',
    )

    @ticket6 = Ticket.create!(
      title: 'test 6',
      group: group1,
      customer_id: 2,
      state: Ticket::State.lookup(name: 'closed'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      close_at: '2015-10-31 12:35:00 UTC',
      created_at: '2015-10-31 12:30:00 UTC',
      updated_at: '2015-10-31 12:30:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: @ticket6.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message article_outbound',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Agent').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      created_at: '2015-10-31 12:30:00 UTC',
      updated_at: '2015-10-31 12:30:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )

    @ticket7 = Ticket.create!(
      title: 'test 7',
      group: group1,
      customer_id: 2,
      state: Ticket::State.lookup(name: 'closed'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      close_at: '2015-11-01 12:30:00 UTC',
      created_at: '2015-11-01 12:30:00 UTC',
      updated_at: '2015-11-01 12:30:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      ticket_id: @ticket7.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message article_outbound',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Agent').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      created_at: '2015-11-01 12:30:00 UTC',
      updated_at: '2015-11-01 12:30:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )

    # execute background jobs
    Scheduler.worker(true)

  end

  teardown do
    if ENV['ES_URL'].present?
      Rake::Task['searchindex:drop'].execute
    end
  end

  test 'compare' do

    # first solution
    result = Report::TicketFirstSolution.aggs(
      range_start: '2015-01-01T00:00:00Z',
      range_end:   '2015-12-31T23:59:59Z',
      interval:    'month', # year, quarter, month, week, day, hour, minute, second
      selector:    {}, # ticket selector to get only a collection of tickets
    )
    assert(result)
    assert_equal(0, result[0])
    assert_equal(0, result[1])
    assert_equal(0, result[2])
    assert_equal(0, result[3])
    assert_equal(0, result[4])
    assert_equal(0, result[5])
    assert_equal(0, result[6])
    assert_equal(0, result[7])
    assert_equal(0, result[8])
    assert_equal(2, result[9])
    assert_equal(1, result[10])
    assert_equal(0, result[11])
    assert_nil(result[12])

    result = Report::TicketFirstSolution.items(
      range_start: '2015-01-01T00:00:00Z',
      range_end:   '2015-12-31T23:59:59Z',
      selector:    {}, # ticket selector to get only a collection of tickets
    )
    assert(result)
    assert_equal(@ticket5.id, result[:ticket_ids][0])
    assert_equal(@ticket6.id, result[:ticket_ids][1])
    assert_equal(@ticket7.id, result[:ticket_ids][2])
    assert_nil(result[:ticket_ids][3])

    # month - with selector #1
    result = Report::TicketFirstSolution.aggs(
      range_start: '2015-01-01T00:00:00Z',
      range_end:   '2015-12-31T23:59:59Z',
      interval:    'month', # year, quarter, month, week, day, hour, minute, second
      selector:    {
        'ticket.priority_id' => {
          'operator' => 'is',
          'value' => [Ticket::Priority.lookup(name: '3 high').id],
        }
      }, # ticket selector to get only a collection of tickets
    )
    assert(result)
    assert_equal(0, result[0])
    assert_equal(0, result[1])
    assert_equal(0, result[2])
    assert_equal(0, result[3])
    assert_equal(0, result[4])
    assert_equal(0, result[5])
    assert_equal(0, result[6])
    assert_equal(0, result[7])
    assert_equal(0, result[8])
    assert_equal(1, result[9])
    assert_equal(0, result[10])
    assert_equal(0, result[11])
    assert_nil(result[12])

    result = Report::TicketFirstSolution.items(
      range_start: '2015-01-01T00:00:00Z',
      range_end:   '2015-12-31T23:59:59Z',
      selector:    {
        'ticket.priority_id' => {
          'operator' => 'is',
          'value' => [Ticket::Priority.lookup(name: '3 high').id],
        }
      }, # ticket selector to get only a collection of tickets
    )
    assert(result)
    assert_equal(@ticket5.id, result[:ticket_ids][0])
    assert_nil(result[:ticket_ids][1])

    # month - with selector #2
    result = Report::TicketFirstSolution.aggs(
      range_start: '2015-01-01T00:00:00Z',
      range_end:   '2015-12-31T23:59:59Z',
      interval:    'month', # year, quarter, month, week, day, hour, minute, second
      selector:    {
        'ticket.priority_id' => {
          'operator' => 'is not',
          'value' => [Ticket::Priority.lookup(name: '3 high').id],
        }
      }, # ticket selector to get only a collection of tickets
    )
    assert(result)
    assert_equal(0, result[0])
    assert_equal(0, result[1])
    assert_equal(0, result[2])
    assert_equal(0, result[3])
    assert_equal(0, result[4])
    assert_equal(0, result[5])
    assert_equal(0, result[6])
    assert_equal(0, result[7])
    assert_equal(0, result[8])
    assert_equal(1, result[9])
    assert_equal(1, result[10])
    assert_equal(0, result[11])
    assert_nil(result[12])

    result = Report::TicketFirstSolution.items(
      range_start: '2015-01-01T00:00:00Z',
      range_end:   '2015-12-31T23:59:59Z',
      selector:    {
        'ticket.priority_id' => {
          'operator' => 'is not',
          'value' => [Ticket::Priority.lookup(name: '3 high').id],
        }
      }, # ticket selector to get only a collection of tickets
    )
    assert(result)
    assert_equal(@ticket6.id, result[:ticket_ids][0])
    assert_equal(@ticket7.id, result[:ticket_ids][1])
    assert_nil(result[:ticket_ids][2])

    # week
    result = Report::TicketFirstSolution.aggs(
      range_start: '2015-10-26T00:00:00Z',
      range_end:   '2015-10-31T23:59:59Z',
      interval:    'week', # year, quarter, month, week, day, hour, minute, second
      selector:    {}, # ticket selector to get only a collection of tickets
    )
    assert(result)
    assert_equal(0, result[0])
    assert_equal(0, result[1])
    assert_equal(1, result[2])
    assert_equal(0, result[3])
    assert_equal(0, result[4])
    assert_equal(1, result[5])
    assert_equal(1, result[6])
    assert_nil(result[7])

    result = Report::TicketFirstSolution.items(
      range_start: '2015-10-26T00:00:00Z',
      range_end:   '2015-11-01T23:59:59Z',
      interval:    'week', # year, quarter, month, week, day, hour, minute, second
      selector:    {}, # ticket selector to get only a collection of tickets
    )
    assert(result)
    assert_equal(@ticket5.id, result[:ticket_ids][0])
    assert_equal(@ticket6.id, result[:ticket_ids][1])
    assert_equal(@ticket7.id, result[:ticket_ids][2])
    assert_nil(result[:ticket_ids][3])

    # day
    result = Report::TicketFirstSolution.aggs(
      range_start: '2015-10-01T00:00:00Z',
      range_end:   '2015-11-01T23:59:59Z',
      interval:    'day', # year, quarter, month, week, day, hour, minute, second
      selector:    {}, # ticket selector to get only a collection of tickets
    )
    assert(result)
    assert_equal(0, result[0])
    assert_equal(0, result[1])
    assert_equal(0, result[2])
    assert_equal(0, result[3])
    assert_equal(0, result[4])
    assert_equal(0, result[5])
    assert_equal(0, result[6])
    assert_equal(0, result[7])
    assert_equal(0, result[8])
    assert_equal(0, result[9])
    assert_equal(0, result[10])
    assert_equal(0, result[11])
    assert_equal(0, result[12])
    assert_equal(0, result[13])
    assert_equal(0, result[14])
    assert_equal(0, result[15])
    assert_equal(0, result[16])
    assert_equal(0, result[17])
    assert_equal(0, result[18])
    assert_equal(0, result[19])
    assert_equal(0, result[20])
    assert_equal(0, result[21])
    assert_equal(0, result[22])
    assert_equal(0, result[23])
    assert_equal(0, result[24])
    assert_equal(0, result[25])
    assert_equal(0, result[26])
    assert_equal(1, result[27])
    assert_equal(0, result[28])
    assert_equal(0, result[29])
    assert_equal(1, result[30])
    assert_nil(result[31])

    result = Report::TicketFirstSolution.items(
      range_start: '2015-10-01T00:00:00Z',
      range_end:   '2015-10-31T23:59:59Z',
      interval:    'day', # year, quarter, month, week, day, hour, minute, second
      selector:    {}, # ticket selector to get only a collection of tickets
    )
    assert(result)
    assert_equal(@ticket5.id, result[:ticket_ids][0])
    assert_equal(@ticket6.id, result[:ticket_ids][1])
    assert_nil(result[:ticket_ids][2])

    # hour
    result = Report::TicketFirstSolution.aggs(
      range_start: '2015-10-28T00:00:00Z',
      range_end:   '2015-10-28T23:59:59Z',
      interval:    'hour', # year, quarter, month, week, day, hour, minute, second
      selector:    {}, # ticket selector to get only a collection of tickets
    )
    assert(result)
    assert_equal(0, result[0])
    assert_equal(0, result[1])
    assert_equal(0, result[2])
    assert_equal(0, result[3])
    assert_equal(0, result[4])
    assert_equal(0, result[5])
    assert_equal(0, result[6])
    assert_equal(0, result[7])
    assert_equal(0, result[8])
    assert_equal(0, result[9])
    assert_equal(0, result[10])
    assert_equal(1, result[11])
    assert_equal(0, result[12])
    assert_equal(0, result[13])
    assert_equal(0, result[14])
    assert_equal(0, result[15])
    assert_equal(0, result[16])
    assert_equal(0, result[17])
    assert_equal(0, result[18])
    assert_equal(0, result[19])
    assert_equal(0, result[20])
    assert_equal(0, result[21])
    assert_equal(0, result[22])
    assert_equal(0, result[23])
    assert_nil(result[24])

    result = Report::TicketFirstSolution.items(
      range_start: '2015-10-28T00:00:00Z',
      range_end:   '2015-10-28T23:59:59Z',
      interval:    'hour', # year, quarter, month, week, day, hour, minute, second
      selector:    {}, # ticket selector to get only a collection of tickets
    )
    assert(result)
    assert_equal(@ticket5.id, result[:ticket_ids][0])
    assert_nil(result[:ticket_ids][1])

    # reopen
    result = Report::TicketReopened.aggs(
      range_start: '2015-01-01T00:00:00Z',
      range_end:   '2015-12-31T23:59:59Z',
      interval:    'month', # year, quarter, month, week, day, hour, minute, second
      selector:    {}, # ticket selector to get only a collection of tickets
    )
    assert(result)
    assert_equal(0, result[0])
    assert_equal(0, result[1])
    assert_equal(0, result[2])
    assert_equal(0, result[3])
    assert_equal(0, result[4])
    assert_equal(0, result[5])
    assert_equal(0, result[6])
    assert_equal(0, result[7])
    assert_equal(0, result[8])
    assert_equal(1, result[9])
    assert_equal(0, result[10])
    assert_equal(0, result[11])
    assert_nil(result[12])

    result = Report::TicketReopened.items(
      range_start: '2015-01-01T00:00:00Z',
      range_end:   '2015-12-31T23:59:59Z',
      selector:    {}, # ticket selector to get only a collection of tickets
    )
    assert(result)
    assert_equal(@ticket5.id, result[:ticket_ids][0])
    assert_nil(result[:ticket_ids][1])

    # month - with selector #1
    result = Report::TicketReopened.aggs(
      range_start: '2015-01-01T00:00:00Z',
      range_end:   '2015-12-31T23:59:59Z',
      interval:    'month', # year, quarter, month, week, day, hour, minute, second
      selector:    {
        'ticket.priority_id' => {
          'operator' => 'is',
          'value' => [Ticket::Priority.lookup(name: '3 high').id],
        }
      }, # ticket selector to get only a collection of tickets
    )
    assert(result)
    assert_equal(0, result[0])
    assert_equal(0, result[1])
    assert_equal(0, result[2])
    assert_equal(0, result[3])
    assert_equal(0, result[4])
    assert_equal(0, result[5])
    assert_equal(0, result[6])
    assert_equal(0, result[7])
    assert_equal(0, result[8])
    assert_equal(1, result[9])
    assert_equal(0, result[10])
    assert_equal(0, result[11])
    assert_nil(result[12])

    result = Report::TicketReopened.items(
      range_start: '2015-01-01T00:00:00Z',
      range_end:   '2015-12-31T23:59:59Z',
      selector:    {
        'ticket.priority_id' => {
          'operator' => 'is',
          'value' => [Ticket::Priority.lookup(name: '3 high').id],
        }
      }, # ticket selector to get only a collection of tickets
    )
    assert(result)
    assert_equal(@ticket5.id, result[:ticket_ids][0])
    assert_nil(result[:ticket_ids][1])

    # month - with selector #2
    result = Report::TicketReopened.aggs(
      range_start: '2015-01-01T00:00:00Z',
      range_end:   '2015-12-31T23:59:59Z',
      interval:    'month', # year, quarter, month, week, day, hour, minute, second
      selector:    {
        'ticket.priority_id' => {
          'operator' => 'is not',
          'value' => [Ticket::Priority.lookup(name: '3 high').id],
        }
      }, # ticket selector to get only a collection of tickets
    )
    assert(result)
    assert_equal(0, result[0])
    assert_equal(0, result[1])
    assert_equal(0, result[2])
    assert_equal(0, result[3])
    assert_equal(0, result[4])
    assert_equal(0, result[5])
    assert_equal(0, result[6])
    assert_equal(0, result[7])
    assert_equal(0, result[8])
    assert_equal(0, result[9])
    assert_equal(0, result[10])
    assert_equal(0, result[11])
    assert_nil(result[12])

    result = Report::TicketReopened.items(
      range_start: '2015-01-01T00:00:00Z',
      range_end:   '2015-12-31T23:59:59Z',
      selector:    {
        'ticket.priority_id' => {
          'operator' => 'is not',
          'value' => [Ticket::Priority.lookup(name: '3 high').id],
        }
      }, # ticket selector to get only a collection of tickets
    )
    assert(result)
    assert_nil(result[:ticket_ids][0])

    # move in/out
    result = Report::TicketMoved.aggs(
      range_start: '2015-01-01T00:00:00Z',
      range_end:   '2015-12-31T23:59:59Z',
      interval:    'month', # year, quarter, month, week, day, hour, minute, second
      selector:    {
        'ticket.group_id' => {
          'operator' => 'is',
          'value' => [Group.lookup(name: 'Users').id],
        }
      }, # ticket selector to get only a collection of tickets
      params: {
        type: 'in',
      },
    )
    assert(result)
    assert_equal(0, result[0])
    assert_equal(0, result[1])
    assert_equal(0, result[2])
    assert_equal(0, result[3])
    assert_equal(0, result[4])
    assert_equal(0, result[5])
    assert_equal(0, result[6])
    assert_equal(0, result[7])
    assert_equal(0, result[8])
    assert_equal(1, result[9])
    assert_equal(0, result[10])
    assert_equal(0, result[11])
    assert_nil(result[12])

    result = Report::TicketMoved.items(
      range_start: '2015-01-01T00:00:00Z',
      range_end:   '2015-12-31T23:59:59Z',
      selector:    {
        'ticket.group_id' => {
          'operator' => 'is',
          'value' => [Group.lookup(name: 'Users').id],
        }
      }, # ticket selector to get only a collection of tickets
      params: {
        type: 'in',
      },
    )
    assert(result)
    assert_equal(@ticket1.id, result[:ticket_ids][0])
    assert_nil(result[:ticket_ids][1])

    # out
    result = Report::TicketMoved.aggs(
      range_start: '2015-01-01T00:00:00Z',
      range_end:   '2015-12-31T23:59:59Z',
      interval:    'month', # year, quarter, month, week, day, hour, minute, second
      selector:    {
        'ticket.group_id' => {
          'operator' => 'is',
          'value' => [Group.lookup(name: 'Users').id],
        }
      }, # ticket selector to get only a collection of tickets
      params: {
        type: 'out',
      },
    )
    assert(result)
    assert_equal(0, result[0])
    assert_equal(0, result[1])
    assert_equal(0, result[2])
    assert_equal(0, result[3])
    assert_equal(0, result[4])
    assert_equal(0, result[5])
    assert_equal(0, result[6])
    assert_equal(0, result[7])
    assert_equal(0, result[8])
    assert_equal(1, result[9])
    assert_equal(0, result[10])
    assert_equal(0, result[11])
    assert_nil(result[12])

    result = Report::TicketMoved.items(
      range_start: '2015-01-01T00:00:00Z',
      range_end:   '2015-12-31T23:59:59Z',
      selector:    {
        'ticket.group_id' => {
          'operator' => 'is',
          'value' => [Group.lookup(name: 'Users').id],
        }
      }, # ticket selector to get only a collection of tickets
      params: {
        type: 'out',
      },
    )
    assert(result)
    assert_equal(@ticket2.id, result[:ticket_ids][0])
    assert_nil(result[:ticket_ids][1])

    # create at
    result = Report::TicketGenericTime.aggs(
      range_start: '2015-01-01T00:00:00Z',
      range_end:   '2015-12-31T23:59:59Z',
      interval:    'month', # year, quarter, month, week, day, hour, minute, second
      selector:    {}, # ticket selector to get only a collection of tickets
      params:      { field: 'created_at' },
    )
    assert(result)
    assert_equal(0, result[0])
    assert_equal(0, result[1])
    assert_equal(0, result[2])
    assert_equal(0, result[3])
    assert_equal(0, result[4])
    assert_equal(0, result[5])
    assert_equal(0, result[6])
    assert_equal(0, result[7])
    assert_equal(0, result[8])
    assert_equal(6, result[9])
    assert_equal(1, result[10])
    assert_equal(0, result[11])
    assert_nil(result[12])

    result = Report::TicketGenericTime.items(
      range_start: '2015-01-01T00:00:00Z',
      range_end:   '2015-12-31T23:59:59Z',
      selector:    {}, # ticket selector to get only a collection of tickets
      params:      { field: 'created_at' },
    )
    assert(result)

    assert_equal(@ticket7.id, result[:ticket_ids][0].to_i)
    assert_equal(@ticket6.id, result[:ticket_ids][1].to_i)
    assert_equal(@ticket5.id, result[:ticket_ids][2].to_i)
    assert_equal(@ticket3.id, result[:ticket_ids][3].to_i)
    assert_equal(@ticket4.id, result[:ticket_ids][4].to_i)
    assert_equal(@ticket2.id, result[:ticket_ids][5].to_i)
    assert_equal(@ticket1.id, result[:ticket_ids][6].to_i)
    assert_nil(result[:ticket_ids][7])

    # cleanup
    Rake::Task['searchindex:drop'].execute
  end

end
