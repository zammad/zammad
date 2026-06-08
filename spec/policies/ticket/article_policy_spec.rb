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

    it { is_expected.to forbid_only_actions(:update, :destroy) }
  end
end
