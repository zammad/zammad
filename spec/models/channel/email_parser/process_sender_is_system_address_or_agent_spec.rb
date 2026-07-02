# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Channel::EmailParser process with sender being a system address or agent', type: :model do

  before do
    EmailAddress.create_or_update(
      channel_id:    1,
      name:          'My System',
      email:         'Myzammad@system.TEST',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

  describe 'sender detection', :aggregate_failures do
    it 'creates the ticket as a customer for an unknown sender, as an agent for the system address, and finds follow-ups by subject' do # rubocop:disable RSpec/ExampleLength
      subject = "some new subject #{SecureRandom.uuid}"
      email_raw_string = "From: me+is+customer@example.com
To: customer@example.com
Subject: #{subject}

Some Text"

      ticket_p, article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
      ticket = Ticket.find(ticket_p.id)
      article = Ticket::Article.find(article_p.id)
      expect(ticket.title).to eq(subject)
      expect(ticket.state.name).to eq('new')
      expect(ticket.create_article_sender.name).to eq('Customer')
      expect(article.sender.name).to eq('Customer')
      expect(ticket.customer.email).to eq('me+is+customer@example.com')

      # check article sender + customer of ticket
      subject = "some new subject #{SecureRandom.uuid}"
      email_raw_string = "From: myzammad@system.test
To: me+is+customer@example.com, customer@example.com
Subject: #{subject}
Message-ID: <123456789-1@linuxhotel.de>


Some Text"

      ticket_p, article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
      ticket = Ticket.find(ticket_p.id)
      article = Ticket::Article.find(article_p.id)

      expect(ticket.title).to eq(subject)
      expect(ticket.state.name).to eq('new')
      expect(ticket.create_article_sender.name).to eq('Agent')
      expect(article.sender.name).to eq('Agent')
      expect(ticket.customer.email).to eq('me+is+customer@example.com')

      # check if follow-up based on inital system sender address

      # follow-up possible because same subject
      email_raw_string = "From: me+is+customer@example.com
To: myzammad@system.test
Subject: #{subject}
Message-ID: <123456789-2@linuxhotel.de>
References: <123456789-1@linuxhotel.de>

Some Text"

      ticket_p2, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
      ticket2 = Ticket.find(ticket_p2.id)
      expect(ticket2.title).to eq(subject)
      expect(ticket2.id).to eq(ticket.id)

      # follow-up not possible because subject has changed
      subject = "new subject without ticket ref #{SecureRandom.uuid}"
      email_raw_string = "From: me+is+customer@example.com
To: myzammad@system.test
Subject: #{subject}
Message-ID: <123456789-3@linuxhotel.de>
References: <123456789-1@linuxhotel.de>

Some Text"

      ticket_p2, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
      ticket2 = Ticket.find(ticket_p2.id)
      expect(ticket2.id).not_to eq(ticket.id)
      expect(ticket2.title).to eq(subject)
      expect(ticket2.state.name).to eq('new')
    end

    it 'assigns the sender to created_by/create_article_sender based on the known customer or agent address, case-insensitively matching the system address' do # rubocop:disable RSpec/ExampleLength
      # create customer
      roles = Role.where(name: 'Customer')
      customer1 = User.create_or_update(
        login:         'ticket-system-sender-customer1@example.com',
        firstname:     'system-sender',
        lastname:      'Customer1',
        email:         'ticket-system-sender-customer1@example.com',
        password:      'customerpw',
        active:        true,
        roles:         roles,
        updated_by_id: 1,
        created_by_id: 1,
      )

      # create agent
      groups = Group.all
      roles  = Role.where(name: 'Agent')
      agent1 = User.create_or_update(
        login:         'ticket-system-sender-agent1@example.com',
        firstname:     'system-sender',
        lastname:      'Agent1',
        email:         'ticket-system-sender-agent1@example.com',
        password:      'agentpw',
        active:        true,
        roles:         roles,
        groups:        groups,
        updated_by_id: 1,
        created_by_id: 1,
      )

      # process customer email
      email_raw_string = "From: ticket-system-sender-customer1@example.com
To: myzammad@system.test
Subject: some subject #1

Some Text"

      ticket_p, article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
      ticket = Ticket.find(ticket_p.id)
      article = Ticket::Article.find(article_p.id)
      expect(ticket.title).to eq('some subject #1')
      expect(ticket.state.name).to eq('new')
      expect(ticket.create_article_sender.name).to eq('Customer')
      expect(article.sender.name).to eq('Customer')
      expect(ticket.customer.email).to eq('ticket-system-sender-customer1@example.com')
      expect(ticket.created_by_id).to eq(customer1.id)
      expect(article.created_by_id).to eq(customer1.id)

      # process agent email
      email_raw_string = "From: ticket-system-sender-agent1@example.com
To: ticket-system-sender-customer1@example.com, myzammad@system.test
Subject: some subject #2

Some Text"

      ticket_p, article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
      ticket = Ticket.find(ticket_p.id)
      article = Ticket::Article.find(article_p.id)
      expect(ticket.title).to eq('some subject #2')
      expect(ticket.state.name).to eq('new')
      expect(ticket.create_article_sender.name).to eq('Agent')
      expect(article.sender.name).to eq('Agent')
      expect(ticket.customer.email).to eq('ticket-system-sender-customer1@example.com')
      expect(ticket.created_by_id).to eq(agent1.id)
      expect(article.created_by_id).to eq(agent1.id)

      email_raw_string = "From: ticket-system-sender-agent1@example.com
To: myzammad@system.test, ticket-system-sender-customer1@example.com
Subject: some subject #3

Some Text"

      ticket_p, article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
      ticket = Ticket.find(ticket_p.id)
      article = Ticket::Article.find(article_p.id)
      expect(ticket.title).to eq('some subject #3')
      expect(ticket.state.name).to eq('new')
      expect(ticket.create_article_sender.name).to eq('Agent')
      expect(article.sender.name).to eq('Agent')
      expect(ticket.customer.email).to eq('ticket-system-sender-customer1@example.com')
      expect(ticket.created_by_id).to eq(agent1.id)
      expect(article.created_by_id).to eq(agent1.id)

      email_raw_string = "From: ticket-system-sender-AGENT1@example.com
To: MYZAMMAD@system.test, ticket-system-sender-CUSTOMER1@example.com
Subject: some subject #4

Some Text"

      ticket_p, article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
      ticket = Ticket.find(ticket_p.id)
      article = Ticket::Article.find(article_p.id)
      expect(ticket.title).to eq('some subject #4')
      expect(ticket.state.name).to eq('new')
      expect(ticket.create_article_sender.name).to eq('Agent')
      expect(article.sender.name).to eq('Agent')
      expect(ticket.customer.email).to eq('ticket-system-sender-customer1@example.com')
      expect(ticket.created_by_id).to eq(agent1.id)
      expect(article.created_by_id).to eq(agent1.id)

      email_raw_string = "From: ticket-system-sender-agent1@example.com
To: myzammad@system.test
Subject: some subject #5

Some Text"

      ticket_p, article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
      ticket = Ticket.find(ticket_p.id)
      article = Ticket::Article.find(article_p.id)
      expect(ticket.title).to eq('some subject #5')
      expect(ticket.state.name).to eq('new')
      expect(ticket.create_article_sender.name).to eq('Agent')
      expect(article.sender.name).to eq('Agent')
      expect(ticket.customer.email).to eq('ticket-system-sender-agent1@example.com')
      expect(ticket.created_by_id).to eq(agent1.id)
      expect(article.created_by_id).to eq(agent1.id)

      email_raw_string = "From: ticket-system-sender-agent1@example.com
To: myZammad@system.Test
Subject: some subject #6

Some Text"

      ticket_p, article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
      ticket = Ticket.find(ticket_p.id)
      article = Ticket::Article.find(article_p.id)
      expect(ticket.title).to eq('some subject #6')
      expect(ticket.state.name).to eq('new')
      expect(ticket.create_article_sender.name).to eq('Agent')
      expect(article.sender.name).to eq('Agent')
      expect(ticket.customer.email).to eq('ticket-system-sender-agent1@example.com')
      expect(ticket.created_by_id).to eq(agent1.id)
      expect(article.created_by_id).to eq(agent1.id)
    end
  end
end
