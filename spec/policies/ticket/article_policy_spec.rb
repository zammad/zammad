# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

describe Ticket::ArticlePolicy do
  subject { described_class.new(user, record) }

  let!(:group) { create(:group) }
  let!(:ticket_customer) { create(:customer) }

  let(:record) do
    ticket = create(:ticket, group: group, customer: ticket_customer)
    create(:ticket_article, ticket: ticket)
  end

  context 'when article internal' do
    let(:record) do
      ticket = create(:ticket, group: group, customer: ticket_customer)
      create(:ticket_article, ticket: ticket, internal: true)
    end

    context 'when agent' do
      let(:user) { create(:agent, groups: [group]) }

      it { is_expected.to permit_actions(%i[show]) }
    end

    context 'when agent and customer' do
      let(:user) { create(:agent_and_customer, groups: [group]) }

      it { is_expected.to permit_actions(%i[show]) }
    end

    context 'when agent and customer but no agent group access' do
      let(:user) do
        customer_role = create(:role, :customer)
        create(:agent_and_customer, roles: [customer_role])
      end

      it { is_expected.not_to permit_actions(%i[show]) }
    end

    context 'when customer' do
      let(:user) { ticket_customer }

      it { is_expected.not_to permit_actions(%i[show]) }
    end
  end

  context 'when agent' do
    let(:user) { create(:agent, groups: [group]) }

    it { is_expected.to permit_actions(%i[show]) }
  end

  context 'when agent and customer' do
    let(:user) { create(:agent_and_customer, groups: [group]) }

    it { is_expected.to permit_actions(%i[show]) }
  end

  context 'when customer' do
    let(:user) { ticket_customer }

    it { is_expected.to permit_actions(%i[show]) }
  end

end
