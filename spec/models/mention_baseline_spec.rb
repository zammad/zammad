# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Mention, type: :model do
  let(:group)    { create(:group) }
  let(:ticket)   { create(:ticket, group: group) }
  let(:agent)    { create(:agent_and_customer, groups: [group]) }
  let(:customer) { create(:customer) }

  # ═══════════════════════════════════════════════
  # Group C -- mentionable? (ANCHORS + TRIPWIRES)
  # ═══════════════════════════════════════════════

  describe '.mentionable? (target check)' do
    it 'C1 (Anker): agent with read access IS mentionable' do
      expect(described_class.mentionable?(ticket, agent)).to be true
    end

    it 'C2 (Anker): agent without group access is NOT mentionable' do
      other_group = create(:group)
      outsider = create(:agent_and_customer, groups: [other_group])
      expect(described_class.mentionable?(ticket, outsider)).to be false
    end

    it 'C4 (Anker): non-Ticket objects are never mentionable' do
      article = create(:ticket_article, ticket: ticket, created_by_id: 1, updated_by_id: 1)
      expect(described_class.mentionable?(article, agent)).to be false
    end

    # --- Phase 3: Tripwire flipped ---

    it 'C3 (Tripwire FLIPPED Phase 3): participant customer IS mentionable with Flag ON' do
      Setting.set('ticket_participants_enabled', true)
      participant = create(:customer)
      own_ticket = create(:ticket, customer: participant, group: group)
      # Customer owns the ticket → show? true → mentionable? true
      expect(described_class).to be_mentionable(own_ticket, participant)
    ensure
      Setting.set('ticket_participants_enabled', false)
    end

    it 'C3-var (UPDATED Phase 3): any customer IS mentionable with Flag ON (pure target check, no show? guard)' do
      Setting.set('ticket_participants_enabled', true)
      stranger = create(:customer)
      # stranger does not own ticket, not participant → show? false
      expect(described_class).to be_mentionable(ticket, stranger)
    ensure
      Setting.set('ticket_participants_enabled', false)
    end

    it 'C5: Flag OFF — customer NOT mentionable (as today)' do
      participant = create(:customer)
      own_ticket = create(:ticket, customer: participant, group: group)
      expect(described_class.mentionable?(own_ticket, participant)).to be false
    end
  end

  # ═══════════════════════════════════════════════
  # Group F -- Lifecycle (PROOF: NO phantom bug)
  # ═══════════════════════════════════════════════

  describe 'lifecycle (Anker)', current_user_id: 1 do
    it 'F1: mentions are destroyed when user is deleted (dependent: :destroy)' do
      described_class.subscribe!(ticket, agent)
      expect { agent.destroy }.to change(described_class, :count).by(-1)
    end

    it 'F2: mentions are destroyed when ticket is deleted' do
      described_class.subscribe!(ticket, agent)
      expect { ticket.destroy }.to change(described_class, :count).by(-1)
    end

    it 'F3: subscribe! writes history entry (HasHistory)' do
      expect { described_class.subscribe!(ticket, agent) }
        .to change(History, :count).by_at_least(1)
    end
  end

  # ═══════════════════════════════════════════════
  # Group G -- NEU-26 Guards (actor vs target)
  # ═══════════════════════════════════════════════

  describe 'actor vs target guards (NEU-26)' do
    it 'G1 (Anker): customer cannot self-subscribe to ticket they cannot see — ControllerPolicy blocks' do
      Setting.set('ticket_participants_enabled', true)
      stranger_ticket = create(:ticket, group: group)
      # mentionable? is true (pure target check) — but ControllerPolicy blocks self-subscribe
      expect(described_class).to be_mentionable(stranger_ticket, customer)
      # The sharp assertion: self-subscribe via REST API is rejected
      policy = Controllers::MentionsControllerPolicy.new(
        customer,
        instance_double(MentionsController, mentionable_object: stranger_ticket, params: { mentionable_type: 'Ticket' })
      )
      expect(policy.create?).to be false
    ensure
      Setting.set('ticket_participants_enabled', false)
    end

    it 'G2 (NOW REAL): agent can add foreign customer as participant via subscribe!', current_user_id: 1 do
      Setting.set('ticket_participants_enabled', true)
      foreign = create(:customer)
      foreign_ticket = create(:ticket, group: group)
      expect do
        described_class.subscribe!(foreign_ticket, foreign)
      end.not_to raise_error
      expect(described_class.subscribed?(foreign_ticket, foreign)).to be true
    ensure
      Setting.set('ticket_participants_enabled', false)
    end

    it 'G3 (Anker): create_mentions? returns false for non-agent' do
      policy = TicketPolicy.new(customer, ticket)
      expect(policy).not_to be_create_mentions
    end
  end

  # ═══════════════════════════════════════════════
  # Phase 3 — Call-Site Tests
  # ═══════════════════════════════════════════════

  describe 'call-site: MentionsControllerPolicy (REST API)' do
    it 'CS1: participant customer can self-subscribe to own ticket via API (Flag ON)' do
      Setting.set('ticket_participants_enabled', true)
      participant = create(:customer)
      own_ticket = create(:ticket, customer: participant, group: group)
      policy = Controllers::MentionsControllerPolicy.new(
        participant,
        instance_double(MentionsController, mentionable_object: own_ticket, params: { mentionable_type: 'Ticket' })
      )
      expect(policy).to be_create
    ensure
      Setting.set('ticket_participants_enabled', false)
    end

    it 'CS2: non-participant customer still REJECTED via API (Flag ON)' do
      Setting.set('ticket_participants_enabled', true)
      policy = Controllers::MentionsControllerPolicy.new(
        customer,
        instance_double(MentionsController, mentionable_object: ticket, params: { mentionable_type: 'Ticket' })
      )
      expect(policy.create?).to be false
    ensure
      Setting.set('ticket_participants_enabled', false)
    end
  end

  describe 'call-site: MentionValidator (model validation)', current_user_id: 1 do
    it 'CS3: participant customer mention passes validation (Flag ON)' do
      Setting.set('ticket_participants_enabled', true)
      participant = create(:customer)
      own_ticket = create(:ticket, customer: participant, group: group)
      mention = described_class.new(user: participant, mentionable: own_ticket,
                                    created_by_id: 1, updated_by_id: 1)
      expect(mention).to be_valid
    ensure
      Setting.set('ticket_participants_enabled', false)
    end

    it 'CS4 (UPDATED): non-participant customer mention now PASSES validation (pure target check)' do
      Setting.set('ticket_participants_enabled', true)
      mention = described_class.new(user: customer, mentionable: ticket,
                                    created_by_id: 1, updated_by_id: 1)
      expect(mention).to be_valid
    ensure
      Setting.set('ticket_participants_enabled', false)
    end
  end

  describe 'call-site: Trigger/perform_changes (attribute_updates)' do
    # The trigger path calls Mention.mentionable?(record, user) inline.
    # We test the mentionable? method directly since the trigger infrastructure
    # requires a full scheduler/trigger setup.

    it 'CS5: trigger mentionable? allows participant customer (Flag ON)' do
      Setting.set('ticket_participants_enabled', true)
      participant = create(:customer)
      own_ticket = create(:ticket, customer: participant, group: group)
      expect(described_class).to be_mentionable(own_ticket, participant)
    ensure
      Setting.set('ticket_participants_enabled', false)
    end

    it 'CS6 (UPDATED): trigger mentionable? now ALLOWS non-participant (pure target check)' do
      Setting.set('ticket_participants_enabled', true)
      expect(described_class).to be_mentionable(ticket, customer)
    ensure
      Setting.set('ticket_participants_enabled', false)
    end
  end

  describe 'participant cap (Phase 5.1)', current_user_id: 1 do
    let(:group)   { Group.first || create(:group) }
    let(:ticket)  { create(:ticket, group: group) }

    before do
      Setting.set('ticket_participants_enabled', true)
    end

    after do
      Setting.set('ticket_participants_enabled', false)
    end

    it 'CAP1: allows exactly 50 customer participants via subscribe!' do
      50.times do
        c = create(:customer)
        own = create(:ticket, customer: c, group: group)
        described_class.subscribe!(own, c)
      end
      expect(described_class.count).to eq 50
    end

    it 'CAP2: 51st customer participant raises error' do
      ticket = create(:ticket, group: group)
      quoted = ActiveRecord::Base.connection.quote('Ticket')
      50.times do
        c = create(:customer)
        ActiveRecord::Base.connection.execute(
          "INSERT INTO mentions (user_id, mentionable_type, mentionable_id, created_by_id, updated_by_id, created_at, updated_at) VALUES (#{c.id}, #{quoted}, #{ticket.id}, 1, 1, NOW(), NOW())"
        )
      end
      customer_51 = create(:customer)
      expect do
        described_class.subscribe!(ticket, customer_51)
      end.to raise_error(Exceptions::UnprocessableContent, %r{50 participants})
    end

    it 'CAP3: agent mentions do NOT count toward cap' do
      60.times do
        a = create(:agent_and_customer, groups: [group])
        described_class.subscribe!(ticket, a)
      end
      customer = create(:customer)
      own = create(:ticket, customer: customer, group: group)
      expect do
        described_class.subscribe!(own, customer)
      end.not_to raise_error
    end

    it 'CAP4: re-subscribe of existing participant does not raise' do
      customer = create(:customer)
      own = create(:ticket, customer: customer, group: group)
      described_class.subscribe!(own, customer)
      expect do
        described_class.subscribe!(own, customer)
      end.not_to raise_error
    end

    it 'CAP-OFF: cap does NOT apply when Flag OFF' do
      Setting.set('ticket_participants_enabled', false)
      60.times do
        a = create(:agent_and_customer, groups: [group])
        described_class.subscribe!(ticket, a)
      end
      expect(ticket.mentions.count).to eq 60
    end

    it 'CAP5: agent_and_customer excluded from cap (49 customers + 1 agent = allowed)' do
      ticket = create(:ticket, group: group)
      quoted = ActiveRecord::Base.connection.quote('Ticket')
      49.times do
        c = create(:customer)
        ActiveRecord::Base.connection.execute(
          "INSERT INTO mentions (user_id, mentionable_type, mentionable_id, created_by_id, updated_by_id, created_at, updated_at) VALUES (#{c.id}, #{quoted}, #{ticket.id}, 1, 1, NOW(), NOW())"
        )
      end
      agent_and_cust = create(:agent_and_customer, groups: [group])
      expect do
        described_class.subscribe!(ticket, agent_and_cust)
      end.not_to raise_error
      expect(ticket.mentions.count).to eq 50
    end

    it 'CAP6: agent_and_customer has participant? access via agent path' do
      Setting.set('ticket_participants_enabled', true)
      agent_and_cust = create(:agent_and_customer, groups: [group])
      own = create(:ticket, customer: agent_and_cust, group: group)
      described_class.subscribe!(own, agent_and_cust)
      policy = TicketPolicy.new(agent_and_cust, own)
      expect(policy).to be_show
    ensure
      Setting.set('ticket_participants_enabled', false)
    end
  end
end
