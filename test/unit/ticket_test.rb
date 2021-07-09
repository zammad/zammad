# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class TicketTest < ActiveSupport::TestCase

  setup do
    Ticket.destroy_all
  end

  test 'ticket create' do
    ticket = Ticket.create!(
      title:         "some title\n äöüß",
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket, 'ticket created')

    assert_equal(ticket.title, 'some title  äöüß', 'ticket.title verify')
    assert_equal(ticket.group.name, 'Users', 'ticket.group verify')
    assert_equal(ticket.state.name, 'new', 'ticket.state verify')

    # create inbound article #1
    article_inbound1 = Ticket::Article.create!(
      ticket_id:     ticket.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message article_inbound1 😍😍😍',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(article_inbound1.body, 'some message article_inbound1 😍😍😍'.utf8_to_3bytesutf8, 'article_inbound.body verify - inbound')

    ticket = Ticket.find(ticket.id)
    assert_equal(ticket.article_count, 1, 'ticket.article_count verify - inbound')
    assert_equal(ticket.last_contact_at.to_s, article_inbound1.created_at.to_s, 'ticket.last_contact verify - inbound')
    assert_equal(ticket.last_contact_customer_at.to_s, article_inbound1.created_at.to_s, 'ticket.last_contact_customer_at verify - inbound')
    assert_nil(ticket.last_contact_agent_at, 'ticket.last_contact_agent_at verify - inbound')
    assert_nil(ticket.first_response_at, 'ticket.first_response_at verify - inbound')
    assert_nil(ticket.close_at, 'ticket.close_at verify - inbound')

    # create inbound article #2
    travel 2.seconds
    article_inbound2 = Ticket::Article.create!(
      ticket_id:     ticket.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message article_inbound2 😍😍😍',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(article_inbound2.body, 'some message article_inbound2 😍😍😍'.utf8_to_3bytesutf8, 'article_inbound.body verify - inbound')

    ticket = Ticket.find(ticket.id)
    assert_equal(ticket.article_count, 2, 'ticket.article_count verify - inbound')
    assert_equal(ticket.last_contact_at.to_s, article_inbound1.created_at.to_s, 'ticket.last_contact verify - inbound')
    assert_equal(ticket.last_contact_customer_at.to_s, article_inbound1.created_at.to_s, 'ticket.last_contact_customer_at verify - inbound')
    assert_nil(ticket.last_contact_agent_at, 'ticket.last_contact_agent_at verify - inbound')
    assert_nil(ticket.first_response_at, 'ticket.first_response_at verify - inbound')
    assert_nil(ticket.close_at, 'ticket.close_at verify - inbound')

    # create note article
    article_note = Ticket::Article.create!(
      ticket_id:     ticket.id,
      from:          'some person',
      subject:       "some\nnote",
      body:          "some\n message",
      internal:      true,
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      type:          Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(article_note.subject, 'some note', 'article_note.subject verify - inbound')
    assert_equal(article_note.body, "some\n message", 'article_note.body verify - inbound')

    ticket = Ticket.find(ticket.id)
    assert_equal(ticket.article_count, 3, 'ticket.article_count verify - note')
    assert_equal(ticket.last_contact_at.to_s, article_inbound1.created_at.to_s, 'ticket.last_contact verify - note')
    assert_equal(ticket.last_contact_customer_at.to_s, article_inbound1.created_at.to_s, 'ticket.last_contact_customer_at verify - note')
    assert_nil(ticket.last_contact_agent_at, 'ticket.last_contact_agent_at verify - note')
    assert_nil(ticket.first_response_at, 'ticket.first_response_at verify - note')
    assert_nil(ticket.close_at, 'ticket.close_at verify - note')

    # create outbound article
    travel 2.seconds
    article_outbound = Ticket::Article.create!(
      ticket_id:     ticket.id,
      from:          'some_recipient@example.com',
      to:            'some_sender@example.com',
      subject:       'some subject',
      message_id:    'some@id2',
      body:          'some message 2',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket = Ticket.find(ticket.id)
    assert_equal(ticket.article_count, 4, 'ticket.article_count verify - outbound')
    assert_equal(ticket.last_contact_at.to_s, article_outbound.created_at.to_s, 'ticket.last_contact verify - outbound')
    assert_equal(ticket.last_contact_customer_at.to_s, article_inbound1.created_at.to_s, 'ticket.last_contact_customer_at verify - outbound')
    assert_equal(ticket.last_contact_agent_at.to_s, article_outbound.created_at.to_s, 'ticket.last_contact_agent_at verify - outbound')
    assert_equal(ticket.first_response_at.to_s, article_outbound.created_at.to_s, 'ticket.first_response_at verify - outbound')
    assert_nil(ticket.close_at, 'ticket.close_at verify - outbound')

    # create inbound article #3
    article_inbound3 = Ticket::Article.create!(
      ticket_id:     ticket.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message article_inbound3 😍😍😍',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(article_inbound3.body, 'some message article_inbound3 😍😍😍'.utf8_to_3bytesutf8, 'article_inbound.body verify - inbound')

    ticket = Ticket.find(ticket.id)
    assert_equal(ticket.article_count, 5, 'ticket.article_count verify - inbound')
    assert_equal(ticket.last_contact_at.to_s, article_inbound3.created_at.to_s, 'ticket.last_contact verify - inbound')
    assert_equal(ticket.last_contact_customer_at.to_s, article_inbound3.created_at.to_s, 'ticket.last_contact_customer_at verify - inbound')
    assert_equal(ticket.last_contact_agent_at.to_s, article_outbound.created_at.to_s, 'ticket.last_contact_agent_at verify - outbound')
    assert_equal(ticket.first_response_at.to_s, article_outbound.created_at.to_s, 'ticket.first_response_at verify - outbound')
    assert_nil(ticket.close_at, 'ticket.close_at verify - outbound')

    # create inbound article #4
    travel 2.seconds
    article_inbound4 = Ticket::Article.create!(
      ticket_id:     ticket.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message article_inbound4 😍😍😍',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(article_inbound4.body, 'some message article_inbound4 😍😍😍'.utf8_to_3bytesutf8, 'article_inbound.body verify - inbound')

    ticket = Ticket.find(ticket.id)
    assert_equal(ticket.article_count, 6, 'ticket.article_count verify - inbound')
    assert_equal(ticket.last_contact_at.to_s, article_inbound3.created_at.to_s, 'ticket.last_contact verify - inbound')
    assert_equal(ticket.last_contact_customer_at.to_s, article_inbound3.created_at.to_s, 'ticket.last_contact_customer_at verify - inbound')
    assert_equal(ticket.last_contact_agent_at.to_s, article_outbound.created_at.to_s, 'ticket.last_contact_agent_at verify - outbound')
    assert_equal(ticket.first_response_at.to_s, article_outbound.created_at.to_s, 'ticket.first_response_at verify - outbound')
    assert_nil(ticket.close_at, 'ticket.close_at verify - outbound')

    ticket.state_id = Ticket::State.where(name: 'closed').first.id
    ticket.save

    ticket = Ticket.find(ticket.id)
    assert_equal(ticket.article_count, 6, 'ticket.article_count verify - state update')
    assert_equal(ticket.last_contact_at.to_s, article_inbound3.created_at.to_s, 'ticket.last_contact verify - state update')
    assert_equal(ticket.last_contact_customer_at.to_s, article_inbound3.created_at.to_s, 'ticket.last_contact_customer_at verify - state update')
    assert_equal(ticket.last_contact_agent_at.to_s, article_outbound.created_at.to_s, 'ticket.last_contact_agent_at verify - state update')
    assert_equal(ticket.first_response_at.to_s, article_outbound.created_at.to_s, 'ticket.first_response_at verify - state update')
    assert(ticket.close_at, 'ticket.close_at verify - state update')

    # set pending time
    ticket.state_id     = Ticket::State.find_by(name: 'pending reminder').id
    ticket.pending_time = Time.zone.parse('1977-10-27 22:00:00 +0000')
    ticket.save

    ticket = Ticket.find(ticket.id)
    assert_equal(ticket.state.name, 'pending reminder', 'state verify')
    assert_equal(ticket.pending_time, Time.zone.parse('1977-10-27 22:00:00 +0000'), 'pending_time verify')

    # reset pending state, should also reset pending time
    ticket.state_id = Ticket::State.find_by(name: 'closed').id
    ticket.save

    ticket = Ticket.find(ticket.id)
    assert_equal(ticket.state.name, 'closed', 'state verify')
    assert_nil(ticket.pending_time)

    # delete article
    article_note = Ticket::Article.create!(
      ticket_id:     ticket.id,
      from:          'some person',
      subject:       'some note',
      body:          'some message',
      internal:      true,
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      type:          Ticket::Article::Type.find_by(name: 'note'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket = Ticket.find(ticket.id)
    assert_equal(ticket.article_count, 7, 'ticket.article_count verify - note')

    article_note.destroy

    ticket = Ticket.find(ticket.id)
    assert_equal(ticket.article_count, 6, 'ticket.article_count verify - note')

    delete = ticket.destroy
    assert(delete, 'ticket destroy')
    travel_back
  end

  test 'ticket latest change' do
    ticket1 = Ticket.create!(
      title:         'latest change 1',
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(Ticket.latest_change.to_s, ticket1.updated_at.to_s)

    travel 1.minute

    ticket2 = Ticket.create!(
      title:         'latest change 2',
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(Ticket.latest_change.to_s, ticket2.updated_at.to_s)

    travel 1.minute

    ticket1.title = 'latest change 1 - 1'
    ticket1.save
    assert_equal(Ticket.latest_change.to_s, ticket1.updated_at.to_s)

    travel 1.minute

    ticket1.touch
    assert_equal(Ticket.latest_change.to_s, ticket1.updated_at.to_s)

    ticket1.destroy
    assert_equal(Ticket.latest_change.to_s, ticket2.updated_at.to_s)
    ticket2.destroy
    travel_back
  end

  test 'ticket process_pending' do

    # close all other pending close tickets first
    Ticket.where.not(pending_time: nil).each do |ticket|
      ticket.state = Ticket::State.lookup(name: 'closed')
      ticket.save!
    end

    ticket = Ticket.create!(
      title:         'pending close test',
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'pending close'),
      pending_time:  Time.zone.now - 60,
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    lookup_ticket = Ticket.find_by('pending_time <= ?', Time.zone.now)
    assert_equal(lookup_ticket.id, ticket.id, 'ticket.pending_time verify')

    Ticket.process_pending

    lookup_ticket = Ticket.find_by('pending_time <= ?', Time.zone.now)
    assert_nil(lookup_ticket, 'ticket.pending_time processed verify')
  end

  test 'ticket subject' do

    ticket = Ticket.create!(
      title:         'subject test 1',
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal('subject test 1', ticket.title)
    assert_equal("ABC subject test 1 [Ticket##{ticket.number}]", ticket.subject_build('ABC subject test 1'))
    assert_equal("RE: ABC subject test 1 [Ticket##{ticket.number}]", ticket.subject_build('ABC subject test 1', 'reply'))
    assert_equal("RE: ABC subject test 1 [Ticket##{ticket.number}]", ticket.subject_build('  ABC subject test 1', 'reply'))
    assert_equal("RE: ABC subject test 1 [Ticket##{ticket.number}]", ticket.subject_build('ABC subject test 1  ', 'reply'))
    assert_equal("FWD: ABC subject test 1 [Ticket##{ticket.number}]", ticket.subject_build('ABC subject test 1  ', 'forward'))
    ticket.destroy

    Setting.set('ticket_hook_position', 'left')

    ticket = Ticket.create!(
      title:         'subject test 1',
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal('subject test 1', ticket.title)
    assert_equal("[Ticket##{ticket.number}] ABC subject test 1", ticket.subject_build('ABC subject test 1'))
    assert_equal("RE: [Ticket##{ticket.number}] ABC subject test 1", ticket.subject_build('ABC subject test 1', 'reply'))
    assert_equal("RE: [Ticket##{ticket.number}] ABC subject test 1", ticket.subject_build('  ABC subject test 1', 'reply'))
    assert_equal("RE: [Ticket##{ticket.number}] ABC subject test 1", ticket.subject_build('ABC subject test 1  ', 'reply'))
    assert_equal("FWD: [Ticket##{ticket.number}] ABC subject test 1", ticket.subject_build('ABC subject test 1  ', 'forward'))
    ticket.destroy

    Setting.set('ticket_hook_position', 'none')

    ticket = Ticket.create!(
      title:         'subject test 1',
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal('subject test 1', ticket.title)
    assert_equal('ABC subject test 1', ticket.subject_build('ABC subject test 1'))
    assert_equal('RE: ABC subject test 1', ticket.subject_build('ABC subject test 1', 'reply'))
    assert_equal('RE: ABC subject test 1', ticket.subject_build('  ABC subject test 1', 'reply'))
    assert_equal('RE: ABC subject test 1', ticket.subject_build('ABC subject test 1  ', 'reply'))
    assert_equal('FWD: ABC subject test 1', ticket.subject_build('ABC subject test 1  ', 'forward'))
    ticket.destroy

  end

  test 'ticket followup number check' do

    origin_backend = Setting.get('ticket_number')
    Setting.set('ticket_number', 'Ticket::Number::Increment')

    ticket1 = Ticket.create!(
      title:         'subject test 1234-1',
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal('subject test 1234-1', ticket1.title)
    assert_equal("ABC subject test 1 [Ticket##{ticket1.number}]", ticket1.subject_build('ABC subject test 1'))
    assert_equal(ticket1.id, Ticket::Number.check("Re: Help [Ticket##{ticket1.number}]").id)

    Setting.set('ticket_number', 'Ticket::Number::Date')
    ticket1 = Ticket.create!(
      title:         'subject test 1234-2',
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal('subject test 1234-2', ticket1.title)
    assert_equal("ABC subject test 1 [Ticket##{ticket1.number}]", ticket1.subject_build('ABC subject test 1'))
    assert_equal(ticket1.id, Ticket::Number.check("Re: Help [Ticket##{ticket1.number}]").id)

    Setting.set('ticket_number', origin_backend)
  end

  test 'article attachment helper 1' do

    ticket1 = Ticket.create!(
      title:         'some article helper test1',
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket1, 'ticket created')

    # create inbound article #1
    article1 = Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      content_type:  'text/html',
      body:          'some message article helper test1 <div><img style="width: 85.5px; height: 49.5px" src="cid:15.274327094.140938@zammad.example.com">asdasd<img src="cid:15.274327094.140939@zammad.example.com"><br>',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    store1 = Store.add(
      object:        'Ticket::Article',
      o_id:          article1.id,
      data:          'content_file1_normally_should_be_an_image',
      filename:      'some_file1.jpg',
      preferences:   {
        'Content-Type'        => 'image/jpeg',
        'Mime-Type'           => 'image/jpeg',
        'Content-ID'          => '15.274327094.140938@zammad.example.com',
        'Content-Disposition' => 'inline'
      },
      created_by_id: 1,
    )
    store2 = Store.add(
      object:        'Ticket::Article',
      o_id:          article1.id,
      data:          'content_file2_normally_should_be_an_image',
      filename:      'some_file2.jpg',
      preferences:   {
        'Content-Type'        => 'image/jpeg',
        'Mime-Type'           => 'image/jpeg',
        'Content-ID'          => '15.274327094.140939@zammad.example.com',
        'Content-Disposition' => 'inline'
      },
      created_by_id: 1,
    )
    store3 = Store.add(
      object:        'Ticket::Article',
      o_id:          article1.id,
      data:          'content_file3',
      filename:      'some_file3.txt',
      preferences:   {
        'Content-Type'        => 'text/stream',
        'Mime-Type'           => 'text/stream',
        'Content-ID'          => '15.274327094.99999@zammad.example.com',
        'Content-Disposition' => 'inline'
      },
      created_by_id: 1,
    )

    article_attributes = Ticket::Article.insert_urls(article1.attributes_with_association_ids)

    assert_no_match('15.274327094.140938@zammad.example.com', article_attributes['body'])
    assert_no_match('15.274327094.140939@zammad.example.com', article_attributes['body'])
    assert_no_match('15.274327094.99999@zammad.example.com', article_attributes['body'])
    assert_match("api/v1/ticket_attachment/#{ticket1.id}/#{article1.id}/#{store1.id}", article_attributes['body'])
    assert_match("api/v1/ticket_attachment/#{ticket1.id}/#{article1.id}/#{store2.id}", article_attributes['body'])
    assert_no_match("api/v1/ticket_attachment/#{ticket1.id}/#{article1.id}/#{store3.id}", article_attributes['body'])

    article1 = Ticket::Article.find(article1.id)
    attachments = article1.attachments_inline
    assert_equal(2, attachments.length)
    assert_equal(store1.id, attachments.first.id)

    ticket1.destroy
  end

  test 'article attachment helper 2' do

    ticket1 = Ticket.create!(
      title:         'some article helper test2',
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket1, 'ticket created')

    # create inbound article #1
    article1 = Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      content_type:  'text/html',
      body:          'some message article helper test2 <div><img src="cid:15.274327094.140938@zammad.example.com">asdasd<img border="0" width="60" height="19" src="cid:15.274327094.140939@zammad.example.com" alt="Beschreibung: Beschreibung: efqmLogo"><br>',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    store1 = Store.add(
      object:        'Ticket::Article',
      o_id:          article1.id,
      data:          'content_file1_normally_should_be_an_image',
      filename:      'some_file1.jpg',
      preferences:   {
        'Content-Type'        => 'image/jpeg',
        'Mime-Type'           => 'image/jpeg',
        'Content-ID'          => '15.274327094.140938@zammad.example.com',
        'Content-Disposition' => 'inline'
      },
      created_by_id: 1,
    )
    store2 = Store.add(
      object:        'Ticket::Article',
      o_id:          article1.id,
      data:          'content_file2_normally_should_be_an_image',
      filename:      'some_file2.jpg',
      preferences:   {
        'Content-Type'        => 'image/jpeg',
        'Mime-Type'           => 'image/jpeg',
        'Content-ID'          => '15.274327094.140939@zammad.example.com',
        'Content-Disposition' => 'inline'
      },
      created_by_id: 1,
    )
    store3 = Store.add(
      object:        'Ticket::Article',
      o_id:          article1.id,
      data:          'content_file3',
      filename:      'some_file3.txt',
      preferences:   {
        'Content-Type'        => 'text/stream',
        'Mime-Type'           => 'text/stream',
        'Content-ID'          => '15.274327094.99999@zammad.example.com',
        'Content-Disposition' => 'inline'
      },
      created_by_id: 1,
    )

    article_attributes = Ticket::Article.insert_urls(article1.attributes_with_association_ids)

    assert_no_match('15.274327094.140938@zammad.example.com', article_attributes['body'])
    assert_no_match('15.274327094.140939@zammad.example.com', article_attributes['body'])
    assert_no_match('15.274327094.99999@zammad.example.com', article_attributes['body'])
    assert_match("api/v1/ticket_attachment/#{ticket1.id}/#{article1.id}/#{store1.id}", article_attributes['body'])
    assert_match("api/v1/ticket_attachment/#{ticket1.id}/#{article1.id}/#{store2.id}", article_attributes['body'])
    assert_no_match("api/v1/ticket_attachment/#{ticket1.id}/#{article1.id}/#{store3.id}", article_attributes['body'])

    article1 = Ticket::Article.find(article1.id)
    attachments = article1.attachments_inline
    assert_equal(2, attachments.length)
    assert_equal(store1.id, attachments.first.id)

    ticket1.destroy
  end

end
