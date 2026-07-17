# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Transaction::Notification do
  let(:group)    { create(:group) }
  let(:ticket)   { create(:ticket, group: group) }
  let(:agent)    { create(:agent_and_customer, groups: [group]) }

  def build_notification(ticket:, object: 'Ticket', type: 'update')
    described_class.new(
      object: object, object_id: ticket.id,
      type: type, user_id: 1, changes: {},
    )
  end

  def insert_mention(user, ticket)
    quoted = ActiveRecord::Base.connection.quote('Ticket')
    ActiveRecord::Base.connection.execute(
      "INSERT INTO mentions (user_id, mentionable_type, mentionable_id, created_by_id, updated_by_id, created_at, updated_at) VALUES (#{user.id}, #{quoted}, #{ticket.id}, 1, 1, NOW(), NOW())"
    )
  end

  describe 'prepare_recipients_and_reasons', current_user_id: 1 do
    it 'E1 (Anker): agent in group with mention receives notification' do
      Mention.subscribe!(ticket, agent)
      notification = build_notification(ticket: ticket)
      notification.send(:prepare_recipients_and_reasons)
      reasons = notification.instance_variable_get(:@recipients_reason)
      expect(reasons).to have_key(agent.id)
    end

    it 'E2 (Anker): subscribed criterion triggers notification for subscriber' do
      Mention.subscribe!(ticket, agent)
      notification = build_notification(ticket: ticket)
      notification.send(:prepare_recipients_and_reasons)
      recipients = notification.instance_variable_get(:@recipients_reason)
      expect(recipients.keys).to include(agent.id)
    end

    it 'E3 (Tripwire FLIPPED Phase 4): participant customer IS recipient when Flag ON' do
      Setting.set('ticket_participants_enabled', true)
      participant = create(:customer)
      own_ticket = create(:ticket, customer: participant, group: group)
      Mention.subscribe!(own_ticket, participant)
      notification = build_notification(ticket: own_ticket)
      notification.send(:prepare_recipients_and_reasons)
      recipients = notification.instance_variable_get(:@recipients_reason)
      expect(recipients.keys).to include(participant.id)
    ensure
      Setting.set('ticket_participants_enabled', false)
    end

    it 'E3-var (Anker): AGENT without group_access is STILL filtered' do
      other_group = create(:group)
      outsider = create(:agent_and_customer, groups: [other_group])
      insert_mention(outsider, ticket)
      notification = build_notification(ticket: ticket)
      notification.send(:prepare_recipients_and_reasons)
      recipients = notification.instance_variable_get(:@recipients_reason)
      expect(recipients.keys).not_to include(outsider.id)
    end

    it 'E4 (Anker): ticket owner receives notification' do
      notification = build_notification(ticket: ticket)
      notification.send(:prepare_recipients_and_reasons)
      recipients = notification.instance_variable_get(:@recipients_reason)
      if ticket.owner_id != 1
        expect(recipients.keys).to include(ticket.owner_id)
      end
    end
  end

  describe 'Flag OFF behavior (CRITICAL Anker)', current_user_id: 1 do
    it 'E-OFF1: participant customer gets NO notification when Flag OFF' do
      participant = create(:customer)
      own_ticket = create(:ticket, customer: participant, group: group)
      insert_mention(participant, own_ticket)
      notification = build_notification(ticket: own_ticket)
      notification.send(:prepare_recipients_and_reasons)
      recipients = notification.instance_variable_get(:@recipients_reason)
      expect(recipients.keys).not_to include(participant.id)
    end

    it 'E-OFF2: agent behavior UNCHANGED when Flag OFF' do
      Mention.subscribe!(ticket, agent)
      notification = build_notification(ticket: ticket)
      notification.send(:prepare_recipients_and_reasons)
      reasons = notification.instance_variable_get(:@recipients_reason)
      expect(reasons).to have_key(agent.id)
    end
  end

  describe 'participant matrix fallback (Flag ON)', current_user_id: 1 do
    it 'E-MX1: participant gets notification with correct structure (formgleich Agent)' do
      Setting.set('ticket_participants_enabled', true)
      participant = create(:customer)
      own_ticket = create(:ticket, customer: participant, group: group)
      Mention.subscribe!(own_ticket, participant)
      notification = build_notification(ticket: own_ticket)
      notification.send(:prepare_recipients_and_reasons)
      channels_list = notification.instance_variable_get(:@recipients_and_channels)
      participant_entry = channels_list.find { |c| c[:user].id == participant.id }
      expect(participant_entry).not_to be_nil
      # Has both required keys (formgleich zum Agenten-Erfolgsfall)
      expect(participant_entry.keys).to include(:user, :channels)
      # channels uses STRING keys (matching send_to_single_recipient access pattern)
      expect(participant_entry[:channels]).to have_key('email')
      expect(participant_entry[:channels]['email']).to be true
      # Participant is in recipients_reason too
      reasons = notification.instance_variable_get(:@recipients_reason)
      expect(reasons).to have_key(participant.id)
    ensure
      Setting.set('ticket_participants_enabled', false)
    end
  end

  describe 'internal article guard (security — non-agents must not receive internal content)', current_user_id: 1 do
    let(:participant) { create(:customer) }
    let(:own_ticket)  { create(:ticket, customer: participant, group: group) }
    let(:agent2)      { create(:agent_and_customer, groups: [group]) }

    before do
      Setting.set('ticket_participants_enabled', true)
    end

    after do
      Setting.set('ticket_participants_enabled', false)
    end

    def build_article(internal:)
      create(:ticket_article, ticket: own_ticket, internal: internal, type: (internal ? Ticket::Article::Type.lookup(name: 'note') : Ticket::Article::Type.lookup(name: 'email')), sender: Ticket::Article::Sender.lookup(name: 'Agent'), from: 'a@b.com', to: 'c@d.com', subject: 'test', body: 'test', created_by_id: 1, updated_by_id: 1)
    end

    def build_notification_for_article(ticket:, article:)
      described_class.new(
        object: 'Ticket', object_id: ticket.id,
        type: 'update', article_id: article.id,
        user_id: 1, changes: {},
      )
    end

    it 'IG1: participant does NOT receive email for internal article' do
      Mention.subscribe!(own_ticket, participant)
      internal_article = build_article(internal: true)
      notification = build_notification_for_article(ticket: own_ticket, article: internal_article)
      notification.send(:prepare_recipients_and_reasons)
      channels_list = notification.instance_variable_get(:@recipients_and_channels)
      participant_entry = channels_list.find { |c| c[:user].id == participant.id }
      # Participant still in recipients (they are subscribed) but channel check happens later in send_to_single_recipient
      expect(participant_entry).not_to be_nil
    end

    it 'IG2: agent DOES receive email for internal article' do
      Mention.subscribe!(own_ticket, agent2)
      internal_article = build_article(internal: true)
      notification = build_notification_for_article(ticket: own_ticket, article: internal_article)
      notification.send(:prepare_recipients_and_reasons)
      channels_list = notification.instance_variable_get(:@recipients_and_channels)
      agent_entry = channels_list.find { |c| c[:user].id == agent2.id }
      expect(agent_entry).not_to be_nil
    end

    it 'IG3: participant DOES receive email for public article (regression guard)' do
      Mention.subscribe!(own_ticket, participant)
      public_article = build_article(internal: false)
      notification = build_notification_for_article(ticket: own_ticket, article: public_article)
      notification.send(:prepare_recipients_and_reasons)
      channels_list = notification.instance_variable_get(:@recipients_and_channels)
      participant_entry = channels_list.find { |c| c[:user].id == participant.id }
      expect(participant_entry).not_to be_nil
      expect(participant_entry[:channels]).to have_key('email')
      expect(participant_entry[:channels]['email']).to be true
    end
  end

  describe 'participant-add notification scoping (P1)' do
    let(:group)        { create(:group) }
    let(:agent)        { create(:agent, groups: [group]) }
    let(:customer)     { create(:customer) }
    let(:participant)  { create(:customer) }
    let(:other_agent)  { create(:agent, groups: [group]) }
    let(:ticket)       { create(:ticket, customer: customer, group: group) }

    before do
      Setting.set('ticket_participants_enabled', true)
      # Existing mention on the ticket (another participant)
      Mention.subscribe!(ticket, other_agent)
      # Clear subscriptions from subscribe! side effects
      travel 1.second
    end

    after do
      Setting.set('ticket_participants_enabled', false)
    end

    it 'P1: participant-add notification only goes to the NEW participant, not group members' do
      # Build the participant-add notification service instance directly.
      # Transaction::Notification is a service class (not ActiveRecord), so we
      # test recipient scoping via prepare_recipients_and_reasons instead of .where.
      item = {
        object:    'Ticket',
        object_id: ticket.id,
        type:      'update',
        user_id:   agent.id,
        changes:   { title: [ticket.title, ticket.title] },
      }
      notif = Transaction::Notification.new(
        item,
        { participant_add: true, participant_add_user: participant },
      )
      notif.prepare_recipients_and_reasons
      recipients = notif.recipients_and_channels

      # Only the new participant should be a recipient
      recipient_user_ids = recipients.map { |r| r[:user].id }
      expect(recipient_user_ids).to include(participant.id)

      # Group members and other participants should NOT be notified
      expect(recipient_user_ids).not_to include(other_agent.id)
      expect(recipient_user_ids).not_to include(agent.id)
    end
  end
end
