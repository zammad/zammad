# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Ticket::ArticlePolicy do
  subject { described_class.new(user, record) }

  let!(:group)           { create(:group) }
  let!(:ticket_customer) { create(:customer) }

  let(:record) do
    ticket = create(:ticket, group: group, customer: ticket_customer)
    create(:ticket_article, ticket: ticket)
  end

  context 'when article internal' do
    let(:record) do
      ticket = create(:ticket, group: group, customer: ticket_customer)
      create(:ticket_article, :internal_note, ticket: ticket, created_by: user)
    end

    context 'when agent' do
      let(:user) { create(:agent, groups: [group]) }

      it { is_expected.to permit_all_actions }
    end

    context 'when agent with read-only access' do
      let(:user) { create(:agent) }

      before do
        user.user_groups.create!(group: group, access: :read)
      end

      it { is_expected.to forbid_only_actions(:create, :update) }
    end

    context 'when agent has all but ticket create access' do
      let(:user) { create(:agent) }

      before do
        user.user_groups.create!(group: group, access: :change)
        user.user_groups.create!(group: group, access: :read)
      end

      it { is_expected.to permit_all_actions }
    end

    context 'when agent and customer' do
      let(:user) { create(:agent_and_customer, groups: [group]) }

      it { is_expected.to permit_all_actions }
    end

    context 'when agent and customer but no agent group access' do
      let(:user) do
        customer_role = create(:role, :customer)
        create(:agent_and_customer, roles: [customer_role])
      end

      it { is_expected.to forbid_all_actions }
    end

    context 'when customer' do
      let(:user) { ticket_customer }

      it { is_expected.to permit_only_actions(:create) } # because internal flag is overriden when saving
    end
  end

  context 'when agent' do
    let(:user) { create(:agent, groups: [group]) }

    it { is_expected.to forbid_only_actions(:destroy) }
  end

  context 'when agent and customer' do
    let(:user) { create(:agent_and_customer, groups: [group]) }

    it { is_expected.to forbid_only_actions(:destroy) }
  end

  context 'when customer' do
    let(:user) { ticket_customer }

    it { is_expected.to permit_only_actions(:create, :show) }
  end

  context 'when customer is agent and customer' do
    let(:user)            { ticket_customer }
    let(:ticket_customer) { create(:agent_and_customer) }

    # #show? is permitted through customer access, #agent_read_access? is not - callers that must
    #   not fall through to customer access ask for the latter.
    it { is_expected.to forbid_only_actions(:update, :destroy, :agent_read_access) }
  end

  describe '#destroy?' do
    subject(:policy) { described_class.new(user, record) }

    let(:user)        { create(:agent, groups: [group]) }
    let(:other_agent) { create(:agent, groups: [group]) }
    let(:ticket)      { create(:ticket, group: group, customer: ticket_customer) }
    let(:record)      { create(:ticket_article, sender_name: 'Agent', internal: true, type_name: 'note', ticket:, created_by_id: user.id) }

    it 'permits deleting an own internal note' do
      expect(policy).to permit_action(:destroy)
    end

    it 'permits it to an admin as well' do
      admin  = create(:admin, groups: [group])
      record = create(:ticket_article, sender_name: 'Agent', internal: true, type_name: 'note', ticket:, created_by_id: admin.id)

      expect(described_class.new(admin, record)).to permit_action(:destroy)
    end

    it 'permits deleting an own internal note 8 minutes later' do
      record
      travel 8.minutes

      expect(policy).to permit_action(:destroy)
    end

    it 'forbids deleting an own internal note 11 minutes later' do
      record
      travel 11.minutes

      expect(policy).to forbid_action(:destroy)
    end

    context 'with a note of another agent' do
      let(:record) { create(:ticket_article, sender_name: 'Agent', internal: true, type_name: 'note', ticket:, created_by_id: other_agent.id) }

      it { is_expected.to forbid_action(:destroy) }
    end

    context 'with a public communication article' do
      let(:record) { create(:ticket_article, sender_name: 'Agent', type_name: 'email', ticket:, created_by_id: user.id) }

      it { is_expected.to forbid_action(:destroy) }
    end

    context 'with an own internal note of a communication type' do
      let(:record) do
        create(:ticket_article_type, name: 'note_communication', communication: true)
        create(:ticket_article, sender_name: 'Agent', internal: true, type_name: 'note_communication', ticket:, created_by_id: user.id)
      end

      it { is_expected.to permit_action(:destroy) }
    end

    context 'when customer' do
      let(:user)   { ticket_customer }
      let(:record) { create(:ticket_article, sender_name: 'Customer', type_name: 'note', ticket:, created_by_id: user.id) }

      it { is_expected.to forbid_action(:destroy) }
    end

    context 'with a custom timeframe' do
      before { Setting.set('ui_ticket_zoom_article_delete_timeframe', 6000) }

      it 'permits deleting before the timeframe ends' do
        record
        travel 5000.seconds

        expect(policy).to permit_action(:destroy)
      end

      it 'forbids deleting after the timeframe ended' do
        record
        travel 8000.seconds

        expect(policy).to forbid_action(:destroy)
      end
    end

    context 'with a timeframe of 0' do
      before { Setting.set('ui_ticket_zoom_article_delete_timeframe', 0) }

      it 'permits deleting at any time' do
        record
        travel 99.days

        expect(policy).to permit_action(:destroy)
      end
    end
  end
end
