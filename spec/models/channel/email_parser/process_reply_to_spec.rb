# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Channel::EmailParser process with Reply-To header', type: :model do

  describe 'postmaster_sender_based_on_reply_to setting', :aggregate_failures do
    it 'keeps the From header as the customer sender and stores no origin_from data when the setting is disabled' do
      Setting.set('postmaster_sender_based_on_reply_to', '')

      email = "From: Bob Smith <marketing_tool@example.com>
To: zammad@example.com
Subject: some new subject
Reply-To: replay_to_customer_process1@example.com

Some Text"

      ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email)
      expect(article_p.sender.name).to eq('Customer')
      expect(article_p.type.name).to eq('email')
      expect(article_p.from).to eq('Bob Smith <marketing_tool@example.com>')
      expect(article_p.reply_to).to eq('replay_to_customer_process1@example.com')
      expect(ticket_p.customer.email).to eq('marketing_tool@example.com')
      expect(ticket_p.customer.firstname).to eq('Bob')
      expect(ticket_p.customer.lastname).to eq('Smith')
      expect(mail[:'raw-origin_from']).to be_nil
      expect(mail[:origin_from]).to be_nil
      expect(mail[:origin_from_email]).to be_nil
      expect(mail[:origin_from_local]).to be_nil
      expect(mail[:origin_from_domain]).to be_nil
      expect(mail[:origin_from_display_name]).to be_nil
    end

    it 'uses the Reply-To header as customer sender and stores the original From data when the setting is "as_sender_of_email"' do # rubocop:disable RSpec/ExampleLength
      Setting.set('postmaster_sender_based_on_reply_to', 'as_sender_of_email')

      email = "From: Bob Smith <marketing_tool@example.com>
To: zammad@example.com
Subject: some new subject
Reply-To: replay_to_customer_process2@example.com

Some Text"

      ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email)
      expect(article_p.from).to eq('replay_to_customer_process2@example.com')
      expect(article_p.reply_to).to eq('replay_to_customer_process2@example.com')
      expect(ticket_p.customer.email).to eq('replay_to_customer_process2@example.com')
      expect(ticket_p.customer.firstname).to eq('')
      expect(ticket_p.customer.lastname).to eq('')

      email = "From: Bob Smith <marketing_tool@example.com>
To: zammad@example.com
Subject: some new subject
Reply-To: Some Name <replay_to_customer_process2-1@example.com>

Some Text"

      ticket_p, article_p, _user_p = Channel::EmailParser.new.process({}, email)
      expect(article_p.sender.name).to eq('Customer')
      expect(article_p.type.name).to eq('email')
      expect(article_p.from).to eq('Some Name <replay_to_customer_process2-1@example.com>')
      expect(article_p.reply_to).to eq('Some Name <replay_to_customer_process2-1@example.com>')
      expect(ticket_p.customer.email).to eq('replay_to_customer_process2-1@example.com')
      expect(ticket_p.customer.firstname).to eq('Some')
      expect(ticket_p.customer.lastname).to eq('Name')
      expect(mail[:'raw-origin_from'].to_s).to eq('Bob Smith <marketing_tool@example.com>')
      expect(mail[:origin_from]).to eq('Bob Smith <marketing_tool@example.com>')
      expect(mail[:origin_from_email]).to eq('marketing_tool@example.com')
      expect(mail[:origin_from_local]).to eq('marketing_tool')
      expect(mail[:origin_from_domain]).to eq('example.com')
      expect(mail[:origin_from_display_name]).to eq('Bob Smith')
    end

    it 'uses the Reply-To header as customer sender and uses the From realname when the setting is "as_sender_of_email_use_from_realname"' do # rubocop:disable RSpec/ExampleLength
      Setting.set('postmaster_sender_based_on_reply_to', 'as_sender_of_email_use_from_realname')

      email = "From: Bob Smith <marketing_tool@example.com>
To: zammad@example.com
Subject: some new subject
Reply-To: replay_to_customer_process3@example.com

Some Text"

      ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email)
      expect(article_p.from).to eq('replay_to_customer_process3@example.com')
      expect(article_p.reply_to).to eq('replay_to_customer_process3@example.com')
      expect(ticket_p.customer.email).to eq('replay_to_customer_process3@example.com')
      expect(ticket_p.customer.firstname).to eq('Bob')
      expect(ticket_p.customer.lastname).to eq('Smith')
      expect(mail[:'raw-origin_from'].to_s).to eq('Bob Smith <marketing_tool@example.com>')
      expect(mail[:origin_from]).to eq('Bob Smith <marketing_tool@example.com>')
      expect(mail[:origin_from_email]).to eq('marketing_tool@example.com')
      expect(mail[:origin_from_local]).to eq('marketing_tool')
      expect(mail[:origin_from_domain]).to eq('example.com')
      expect(mail[:origin_from_display_name]).to eq('Bob Smith')

      email = "From: Bob Smith <marketing_tool@example.com>
To: zammad@example.com
Subject: some new subject
Reply-To: Some Name <replay_to_customer_process3-1@example.com>

Some Text"

      ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email)
      expect(article_p.sender.name).to eq('Customer')
      expect(article_p.type.name).to eq('email')
      expect(article_p.from).to eq('Some Name <replay_to_customer_process3-1@example.com>')
      expect(article_p.reply_to).to eq('Some Name <replay_to_customer_process3-1@example.com>')
      expect(ticket_p.customer.email).to eq('replay_to_customer_process3-1@example.com')
      expect(ticket_p.customer.firstname).to eq('Bob')
      expect(ticket_p.customer.lastname).to eq('Smith')
      expect(mail[:'raw-origin_from'].to_s).to eq('Bob Smith <marketing_tool@example.com>')
      expect(mail[:origin_from]).to eq('Bob Smith <marketing_tool@example.com>')
      expect(mail[:origin_from_email]).to eq('marketing_tool@example.com')
      expect(mail[:origin_from_local]).to eq('marketing_tool')
      expect(mail[:origin_from_domain]).to eq('example.com')
      expect(mail[:origin_from_display_name]).to eq('Bob Smith')
    end

    it 'uses the Reply-To header as customer sender when the From address is a known system address' do
      Setting.set('postmaster_sender_based_on_reply_to', 'as_sender_of_email')

      EmailAddress.create!(
        name:          'address #1',
        email:         'marketing_tool@example.com',
        active:        true,
        updated_by_id: 1,
        created_by_id: 1,
      )

      email = "From: Marketing Tool <marketing_tool@example.com>
To: zammad@example.com
Subject: some new subject
Reply-To: replay_to_customer_process2@example.com

Some Text"

      ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email)
      expect(article_p.sender.name).to eq('Customer')
      expect(article_p.type.name).to eq('email')
      expect(article_p.from).to eq('replay_to_customer_process2@example.com')
      expect(article_p.reply_to).to eq('replay_to_customer_process2@example.com')
      expect(ticket_p.customer.email).to eq('replay_to_customer_process2@example.com')
      expect(ticket_p.customer.firstname).to eq('')
      expect(ticket_p.customer.lastname).to eq('')
      expect(mail[:'raw-origin_from'].to_s).to eq('Marketing Tool <marketing_tool@example.com>')
      expect(mail[:origin_from]).to eq('Marketing Tool <marketing_tool@example.com>')
      expect(mail[:origin_from_email]).to eq('marketing_tool@example.com')
      expect(mail[:origin_from_local]).to eq('marketing_tool')
      expect(mail[:origin_from_domain]).to eq('example.com')
      expect(mail[:origin_from_display_name]).to eq('Marketing Tool')
    end
  end
end
