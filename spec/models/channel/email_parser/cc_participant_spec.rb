# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe "Channel::EmailParser CC and participants", :aggregate_failures, type: :model, current_user_id: 1 do
  let(:group)      { create(:group) }
  let(:ticket)     { create(:ticket, group: group) }
  let(:customer)   { create(:customer) }

  let(:raw_mail) do
    <<~MAIL
      From: sender@test.local
      To: support@test.local
      Cc: #{cc_recipient}
      Subject: CC participant test

      Test body
    MAIL
  end

  def process_mail
    Channel::EmailParser.new.process({ group_id: group.id, trusted: false }, raw_mail)
  end

  before do
    Setting.set('ticket_participants_enabled', true)
  end

  after do
    Setting.set('ticket_participants_enabled', false)
  end

  # ANKER 1: CC recipient already participant → no duplicate mention, no crash
  context 'when CC recipient is already a participant' do
    let(:cc_recipient) { "#{customer.firstname} <#{customer.email}>" }

    before do
      Mention.subscribe!(ticket, customer)
    end

    it 'does not create a duplicate mention (Anker: Status quo)' do
      expect { process_mail }.not_to change { ticket.mentions.count }
    end

    it 'does not crash the postmaster pipeline' do
      expect { process_mail }.not_to raise_error
    end
  end

  # ANKER 2: CC recipient is NOT a participant → NO automatic mention
  # This is the protection line against future auto-CC (NEU-27).
  # If someone builds CC-auto-add without gates, this test turns RED.
  context 'when CC recipient is NOT a participant' do
    let(:cc_recipient) { "#{customer.firstname} <#{customer.email}>" }

    it 'does NOT automatically add CC recipient as participant (Anker: Schutzlinie)' do
      expect { process_mail }.not_to change(Mention, :count)
    end

    it 'creates the ticket and article normally' do
      result_ticket, article = process_mail
      expect(result_ticket).to be_persisted
      expect(article).to be_persisted
    end
  end
end
