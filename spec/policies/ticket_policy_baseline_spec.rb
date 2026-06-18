require 'rails_helper'

RSpec.describe TicketPolicy, type: :policy do
  let(:group)   { create(:group) }
  let(:ticket)  { create(:ticket, group: group) }

  # ═══════════════════════════════════════════════
  # Group A -- Agent access (REGRESSION ANCHORS)
  # ═══════════════════════════════════════════════

  describe 'agent access (Anker)' do
    let(:agent) { create(:agent_and_customer, groups: [group]) }

    it 'A1: agent with read access can show?' do
      policy = described_class.new(agent, ticket)
      expect(policy.show?).to be_truthy
    end

    it 'A2: agent with full/change can update?' do
      policy = described_class.new(agent, ticket)
      expect(policy.update?).to be true
    end

    it 'A3: agent_read_access? is true for agent in group' do
      policy = described_class.new(agent, ticket)
      expect(policy.agent_read_access?).to be true
    end

    it 'A4: agent without group access cannot show?' do
      other_group = create(:group)
      outsider = create(:agent_and_customer, groups: [other_group])
      policy = described_class.new(outsider, ticket)
      expect(policy.show?).to be false
    end

    it 'A5: agent_read_access? reflects group permissions' do
      policy = described_class.new(agent, ticket)
      expect(policy.agent_read_access?).to be true
    end
  end

  # ═══════════════════════════════════════════════
  # Group B -- Customer access (ANCHORS)
  # ═══════════════════════════════════════════════

  describe 'customer access (Anker)' do
    let(:customer) { create(:customer) }

    it 'B1: ticket owner can show? (returns FieldScope)' do
      owned = create(:ticket, customer: customer, group: group)
      policy = described_class.new(customer, owned)
      result = policy.show?
      expect(result).to be_truthy
      expect(result).to be_a(ApplicationPolicy::FieldScope)
    end

    it 'B2: non-owner customer cannot show?' do
      policy = described_class.new(customer, ticket)
      expect(policy.show?).to be false
    end

    it 'B4: customer FieldScope denies internal fields' do
      owned = create(:ticket, customer: customer, group: group)
      policy = described_class.new(customer, owned)
      result = policy.show?
      expect(result.deny).to include(:ai_agent_running)
      expect(result.deny).to include(:checklist)
    end

    it 'B5: internal articles exist (access controlled by FieldScope)' do
      owned = create(:ticket, customer: customer, group: group)
      create(:ticket_article, ticket: owned, internal: true, created_by_id: 1, updated_by_id: 1)
      create(:ticket_article, ticket: owned, internal: false, created_by_id: 1, updated_by_id: 1)
      expect(owned.articles.count).to eq 2
    end
  end

  # ═══════════════════════════════════════════════
  # Group D -- ReadScope (ANCHORS + TRIPWIRE)
  # ═══════════════════════════════════════════════

  describe 'ReadScope' do
    let(:customer) { create(:customer) }
    let(:agent)    { create(:agent_and_customer, groups: [group]) }

    it 'D1 (Anker): agent ReadScope resolves' do
      agent.user_groups.each { |ug| ug.update_columns(access: 'full') }
      scope = described_class::ReadScope.new(agent)
      expect { scope.resolve.load }.not_to raise_error
    end

    it 'D2 (Anker): customer sees only own tickets' do
      owned = create(:ticket, customer: customer, group: group)
      other = create(:ticket, group: group)
      scope = described_class::ReadScope.new(customer)
      ids = scope.resolve.pluck(:id)
      expect(ids).to include(owned.id)
      expect(ids).not_to include(other.id)
    end

    it 'D3 (Tripwire FLIPPED in Phase 2): customer with mention SEES ticket when feature ON' do
      Setting.set('ticket_participants_enabled', true)
      stranger = create(:customer)
      quoted_type = ActiveRecord::Base.connection.quote('Ticket')
      ActiveRecord::Base.connection.execute(
        "INSERT INTO mentions (user_id, mentionable_type, mentionable_id, created_by_id, updated_by_id, created_at, updated_at) VALUES (#{stranger.id}, #{quoted_type}, #{ticket.id}, 1, 1, NOW(), NOW())"
      )
      scope = described_class::ReadScope.new(stranger)
      ids = scope.resolve.pluck(:id)
      expect(ids).to include(ticket.id)
    ensure
      Setting.set('ticket_participants_enabled', false)
    end

    it 'D4 (Anker): user without ticket.* permission sees nothing' do
      nobody = create(:user, roles: [])
      scope = described_class::ReadScope.new(nobody)
      expect(scope.resolve).to be_empty
    end
  end

  # ═══════════════════════════════════════════════
  # Phase 2 -- Participant access (FEATURE ON)
  # ═══════════════════════════════════════════════

  describe 'participant access (Phase 2, Flag ON)' do
    let(:participant) { create(:customer) }
    let(:stranger)    { create(:customer) }

    before do
      Setting.set('ticket_participants_enabled', true)
      quoted_type = ActiveRecord::Base.connection.quote('Ticket')
      ActiveRecord::Base.connection.execute(
        "INSERT INTO mentions (user_id, mentionable_type, mentionable_id, created_by_id, updated_by_id, created_at, updated_at) VALUES (#{participant.id}, #{quoted_type}, #{ticket.id}, 1, 1, NOW(), NOW())"
      )
    end

    after do
      Setting.set('ticket_participants_enabled', false)
    end

    it 'P1: participant can show? ticket (returns FieldScope)' do
      policy = described_class.new(participant, ticket)
      result = policy.show?
      expect(result).to be_truthy
      expect(result).to be_a(ApplicationPolicy::FieldScope)
    end

    it 'P2: participant CANNOT update? ticket' do
      policy = described_class.new(participant, ticket)
      expect(policy.update?).to be false
    end

    it 'P3: participant sees ticket in ReadScope list' do
      scope = described_class::ReadScope.new(participant)
      ids = scope.resolve.pluck(:id)
      expect(ids).to include(ticket.id)
    end

    it 'P4: stranger (non-participant) still cannot show?' do
      policy = described_class.new(stranger, ticket)
      expect(policy.show?).to be false
    end
  end

  describe 'participant access (Phase 2, Flag OFF)' do
    let(:participant) { create(:customer) }

    before do
      quoted_type = ActiveRecord::Base.connection.quote('Ticket')
      ActiveRecord::Base.connection.execute(
        "INSERT INTO mentions (user_id, mentionable_type, mentionable_id, created_by_id, updated_by_id, created_at, updated_at) VALUES (#{participant.id}, #{quoted_type}, #{ticket.id}, 1, 1, NOW(), NOW())"
      )
    end

    it 'P5: with Flag OFF, participant gets NOTHING (show? false)' do
      policy = described_class.new(participant, ticket)
      expect(policy.show?).to be false
    end

    it 'P6: with Flag OFF, participant NOT in ReadScope' do
      scope = described_class::ReadScope.new(participant)
      ids = scope.resolve.pluck(:id)
      expect(ids).not_to include(ticket.id)
    end
  end

  describe 'active filter - participant? (PR-2)' do
    let(:participant) { create(:customer) }

    before do
      Setting.set('ticket_participants_enabled', true)
      quoted_type = ActiveRecord::Base.connection.quote('Ticket')
      ActiveRecord::Base.connection.execute(
        "INSERT INTO mentions (user_id, mentionable_type, mentionable_id, created_by_id, updated_by_id, created_at, updated_at) VALUES (#{participant.id}, #{quoted_type}, #{ticket.id}, 1, 1, NOW(), NOW())"
      )
    end

    after do
      Setting.set('ticket_participants_enabled', false)
    end

    it 'AF1: active participant → participant? = true' do
      policy = described_class.new(participant, ticket)
      expect(policy.send(:participant?)).to be true
    end

    it 'AF2: deactivated participant → participant? = false' do
      participant.update!(active: false)
      policy = described_class.new(participant, ticket)
      expect(policy.send(:participant?)).to be false
    end
  end

  describe 'active filter - ReadScope (PR-2)' do
    let(:participant) { create(:customer) }

    before do
      Setting.set('ticket_participants_enabled', true)
      quoted_type = ActiveRecord::Base.connection.quote('Ticket')
      ActiveRecord::Base.connection.execute(
        "INSERT INTO mentions (user_id, mentionable_type, mentionable_id, created_by_id, updated_by_id, created_at, updated_at) VALUES (#{participant.id}, #{quoted_type}, #{ticket.id}, 1, 1, NOW(), NOW())"
      )
    end

    after do
      Setting.set('ticket_participants_enabled', false)
    end

    it 'AF3: active participant sees ticket in ReadScope' do
      scope = described_class::ReadScope.new(participant)
      ids = scope.resolve.pluck(:id)
      expect(ids).to include(ticket.id)
    end

    it 'AF4: deactivated participant does NOT see ticket in ReadScope' do
      participant.update!(active: false)
      scope = described_class::ReadScope.new(participant)
      ids = scope.resolve.pluck(:id)
      expect(ids).not_to include(ticket.id)
    end
  end
end
