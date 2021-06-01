# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class EmailDeliverTest < ActiveSupport::TestCase
  test 'basic check' do
    travel_to DateTime.current

    if ENV['MAIL_SERVER'].blank?
      raise "Need MAIL_SERVER as ENV variable like export MAIL_SERVER='mx.example.com'"
    end
    if ENV['MAIL_SERVER_ACCOUNT'].blank?
      raise "Need MAIL_SERVER_ACCOUNT as ENV variable like export MAIL_SERVER_ACCOUNT='user:somepass'"
    end

    if ENV['MAIL_SERVER_EMAIL'].blank?
      raise "Need MAIL_SERVER_EMAIL as ENV variable like export MAIL_SERVER_EMAIL='someunitest@example.com'"
    end

    server_login = ENV['MAIL_SERVER_ACCOUNT'].split(':')[0]
    server_password = ENV['MAIL_SERVER_ACCOUNT'].split(':')[1]

    email_address = EmailAddress.create!(
      realname:      'me Helpdesk',
      email:         "some-zammad-#{ENV['MAIL_SERVER_EMAIL']}",
      updated_by_id: 1,
      created_by_id: 1,
    )

    group = Group.create_or_update(
      name:             'DeliverTest',
      email_address_id: email_address.id,
      updated_by_id:    1,
      created_by_id:    1,
    )

    channel = Channel.create!(
      area:          'Email::Account',
      group_id:      group.id,
      options:       {
        inbound:  {
          adapter: 'imap',
          options: {
            host:     'mx1.example.com',
            user:     'example',
            password: 'some_pw',
            ssl:      true,
          }
        },
        outbound: {
          adapter: 'sendmail'
        }
      },
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    email_address.channel_id = channel.id
    email_address.save!

    ticket1 = Ticket.create!(
      title:         'some delivery test',
      group:         group,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket1, 'ticket created')

    article1 = Ticket::Article.create!(
      ticket_id:     ticket1.id,
      to:            'some_recipient@example_not_existing_what_ever.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message delivery test',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_nil(article1.preferences['delivery_retry'])
    assert_nil(article1.preferences['delivery_status'])
    assert_nil(article1.preferences['delivery_status_date'])
    assert_nil(article1.preferences['delivery_status_message'])

    TicketArticleCommunicateEmailJob.new.perform(article1.id)

    article1_lookup = Ticket::Article.find(article1.id)
    assert_equal(1, article1_lookup.preferences['delivery_retry'])
    assert_equal('success', article1_lookup.preferences['delivery_status'])
    assert(article1_lookup.preferences['delivery_status_date'])
    assert_nil(article1_lookup.preferences['delivery_status_message'])

    # send with invalid smtp settings
    channel.update!(
      options: {
        inbound:  {
          adapter: 'imap',
          options: {
            host:     'mx1.example.com',
            user:     'example',
            password: 'some_pw',
            ssl:      true,
          }
        },
        outbound: {
          adapter: 'smtp',
          options: {
            host:      'mx1.example.com',
            port:      25,
            start_tls: true,
            user:      'not_existing',
            password:  'not_existing',
          },
        },
      },
    )
    assert_raises(RuntimeError) do
      TicketArticleCommunicateEmailJob.new.perform(article1.id)
    end
    article1_lookup = Ticket::Article.find(article1.id)
    assert_equal(2, article1_lookup.preferences['delivery_retry'])
    assert_equal('fail', article1_lookup.preferences['delivery_status'])
    assert(article1_lookup.preferences['delivery_status_date'])
    assert(article1_lookup.preferences['delivery_status_message'])

    # send with correct smtp settings
    channel.update!(
      options: {
        inbound:  {
          adapter: 'imap',
          options: {
            host:     'mx1.example.com',
            user:     'example',
            password: 'some_pw',
            ssl:      true,
          }
        },
        outbound: {
          adapter: 'smtp',
          options: {
            host:      ENV['MAIL_SERVER'],
            port:      25,
            start_tls: true,
            user:      server_login,
            password:  server_password,
          },
        },
      },
    )

    TicketArticleCommunicateEmailJob.new.perform(article1.id)
    article1_lookup = Ticket::Article.find(article1.id)
    assert_equal(3, article1_lookup.preferences['delivery_retry'])
    assert_equal('success', article1_lookup.preferences['delivery_status'])
    assert(article1_lookup.preferences['delivery_status_date'])
    assert_nil(article1_lookup.preferences['delivery_status_message'])

    # check retry jobs
    # remove background jobs
    Delayed::Job.destroy_all

    # send with invalid smtp settings
    channel.update!(
      options: {
        inbound:  {
          adapter: 'imap',
          options: {
            host:     'mx1.example.com',
            user:     'example',
            password: 'some_pw',
            ssl:      true,
          }
        },
        outbound: {
          adapter: 'smtp',
          options: {
            host:      'mx1.example.com',
            port:      25,
            start_tls: true,
            user:      'not_existing',
            password:  'not_existing',
          },
        },
      },
    )

    # remove background jobs
    Delayed::Job.destroy_all

    article2 = Ticket::Article.create!(
      ticket_id:     ticket1.id,
      to:            'some_recipient@example_not_existing_what_ever.com',
      subject:       'some subject2',
      message_id:    'some@id',
      body:          'some message delivery test2',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket1.state = Ticket::State.find_by(name: 'closed')
    ticket1.save

    assert(Delayed::Job.where(attempts: 1).none?)
    Scheduler.worker(true)
    assert(Delayed::Job.exists?(attempts: 1))
    ticket1.reload

    article2_lookup = Ticket::Article.find(article2.id)
    assert_equal(2, ticket1.articles.count)
    assert_equal(1, article2_lookup.preferences['delivery_retry'])
    assert_equal('fail', article2_lookup.preferences['delivery_status'])
    assert(article2_lookup.preferences['delivery_status_date'])
    assert(article2_lookup.preferences['delivery_status_message'])

    Scheduler.worker(true)
    ticket1.reload

    article2_lookup = Ticket::Article.find(article2.id)
    assert_equal(2, ticket1.articles.count)
    assert_equal(1, article2_lookup.preferences['delivery_retry'])
    assert_equal('fail', article2_lookup.preferences['delivery_status'])
    assert(article2_lookup.preferences['delivery_status_date'])
    assert(article2_lookup.preferences['delivery_status_message'])
    assert_equal('closed', ticket1.state.name)

    travel 26.seconds
    assert(Delayed::Job.where(attempts: 2).none?)
    Scheduler.worker(true)
    assert(Delayed::Job.exists?(attempts: 2))
    ticket1.reload

    article2_lookup = Ticket::Article.find(article2.id)
    assert_equal(2, ticket1.articles.count)
    assert_equal(2, article2_lookup.preferences['delivery_retry'])
    assert_equal('fail', article2_lookup.preferences['delivery_status'])
    assert(article2_lookup.preferences['delivery_status_date'])
    assert(article2_lookup.preferences['delivery_status_message'])
    assert_equal('closed', ticket1.state.name)

    Scheduler.worker(true)
    ticket1.reload

    article2_lookup = Ticket::Article.find(article2.id)
    assert_equal(2, ticket1.articles.count)
    assert_equal(2, article2_lookup.preferences['delivery_retry'])
    assert_equal('fail', article2_lookup.preferences['delivery_status'])
    assert(article2_lookup.preferences['delivery_status_date'])
    assert(article2_lookup.preferences['delivery_status_message'])
    assert_equal('closed', ticket1.state.name)

    travel 51.seconds
    assert(Delayed::Job.where(attempts: 3).none?)
    Scheduler.worker(true)
    assert(Delayed::Job.exists?(attempts: 3))
    ticket1.reload

    article2_lookup = Ticket::Article.find(article2.id)
    assert_equal(2, ticket1.articles.count)
    assert_equal(3, article2_lookup.preferences['delivery_retry'])
    assert_equal('fail', article2_lookup.preferences['delivery_status'])
    assert(article2_lookup.preferences['delivery_status_date'])
    assert(article2_lookup.preferences['delivery_status_message'])
    assert_equal('closed', ticket1.state.name)

    travel 76.seconds
    assert(Delayed::Job.where(attempts: 4).none?)
    assert_raises(RuntimeError) do
      Scheduler.worker(true)
    end
    assert(Delayed::Job.none?)
    ticket1.reload

    article2_lookup = Ticket::Article.find(article2.id)
    article_delivery_system = ticket1.articles.last
    assert_equal(3, ticket1.articles.count)
    assert_equal(4, article2_lookup.preferences['delivery_retry'])
    assert_equal('fail', article2_lookup.preferences['delivery_status'])
    assert(article2_lookup.preferences['delivery_status_date'])
    assert(article2_lookup.preferences['delivery_status_message'])
    assert_equal('System', article_delivery_system.sender.name)
    assert_equal(true, article_delivery_system.preferences['delivery_message'])
    assert_equal(article2.id, article_delivery_system.preferences['delivery_article_id_related'])
    assert_equal(true, article_delivery_system.preferences['notification'])
    assert_equal(Ticket::State.find_by(default_follow_up: true).name, ticket1.state.name)
  end

end
