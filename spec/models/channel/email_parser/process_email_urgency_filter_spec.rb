# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Channel::EmailParser email urgency', type: :model do
  let(:group)   { Group.lookup(name: 'Users') }
  let(:result)  { Channel::EmailParser.new.process({ group_id: group.id, trusted: false }, raw_email) }
  let(:ticket)  { result[0] }

  # Zammad seeds no filter on this match key; it takes effect only once an
  # administrator configures one, as this example does.
  before do
    create(:postmaster_filter,
           match:   { 'email-urgency' => { 'operator' => 'is any of', 'value' => [EmailUrgency::HIGH] } },
           perform: { 'x-zammad-ticket-priority_id' => { 'value' => Ticket::Priority.lookup(name: '3 high').id.to_s } })
  end

  def mail_with(headers)
    <<~MAIL
      From: sender@example.com
      To: zammad@example.com
      Subject: urgency test
      Message-ID: <#{SecureRandom.uuid}@example.com>
      #{headers}
      Content-Type: text/plain; charset=UTF-8

      some text
    MAIL
  end

  context 'with the standardized Importance header' do
    let(:raw_email) { mail_with('Importance: high') }

    it 'matches the filter' do
      expect(ticket.priority.name).to eq('3 high')
    end
  end

  # Matching the normalized field means every header EmailUrgency reads reaches
  # the filter, not just the one it was written for.
  context 'with the standardized Priority header' do
    let(:raw_email) { mail_with('Priority: urgent') }

    it 'matches the filter' do
      expect(ticket.priority.name).to eq('3 high')
    end
  end

  context 'with a Thunderbird flavoured urgent email' do
    let(:raw_email) { mail_with('X-Priority: 1 (Highest)') }

    it 'matches the filter' do
      expect(ticket.priority.name).to eq('3 high')
    end
  end

  context 'with the X-MSMail-Priority header alone' do
    let(:raw_email) { mail_with('X-MSMail-Priority: High') }

    it 'matches the filter' do
      expect(ticket.priority.name).to eq('3 high')
    end
  end

  context 'with an Outlook flavoured urgent email' do
    let(:raw_email) { mail_with("X-Priority: 1\nX-MSMail-Priority: High\nImportance: high") }

    it 'matches the filter' do
      expect(ticket.priority.name).to eq('3 high')
    end
  end

  # RFC 5322 section 1.2.2: header names are case insensitive. Thunderbird gets
  # this wrong for X-Priority (Mozilla bug 1167002), Zammad must not.
  context 'with a lower case header name' do
    let(:raw_email) { mail_with('x-priority: 1') }

    it 'matches the filter' do
      expect(ticket.priority.name).to eq('3 high')
    end
  end

  # [MS-OXCMAIL] appendix A note <110>: Exchange 2007 and later use the last
  # instance of a repeated header. Zammad lands on the same value.
  context 'with a header the sender repeated' do
    let(:raw_email) { mail_with("Importance: low\nImportance: high") }

    it 'matches the filter' do
      expect(ticket.priority.name).to eq('3 high')
    end
  end

  context 'with a standardized high and a vendor low header' do
    let(:raw_email) { mail_with("Importance: high\nX-Priority: 5 (Lowest)") }

    it 'matches the filter' do
      expect(ticket.priority.name).to eq('3 high')
    end
  end

  context 'with a standardized low and a vendor high header' do
    let(:raw_email) { mail_with("Importance: low\nX-Priority: 1 (Highest)") }

    it 'does not match the filter' do
      expect(ticket.priority.name).to eq('2 normal')
    end
  end

  context 'with an urgency header Zammad does not understand' do
    let(:raw_email) { mail_with('Importance: super-duper-important') }

    it 'does not match the filter' do
      expect(ticket.priority.name).to eq('2 normal')
    end
  end

  # Holds only because the derived fields are merged last, even when nil.
  context 'with a spoofed Email-Urgency header' do
    let(:raw_email) { mail_with('Email-Urgency: high') }

    it 'does not match the filter' do
      expect(ticket.priority.name).to eq('2 normal')
    end
  end

  context 'without any urgency header' do
    let(:raw_email) { mail_with('X-Mailer: whatever') }

    it 'does not match the filter' do
      expect(ticket.priority.name).to eq('2 normal')
    end
  end
end
