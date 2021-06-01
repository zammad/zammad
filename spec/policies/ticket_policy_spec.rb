# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

describe TicketPolicy do
  subject { described_class.new(user, record) }

  let(:record) { create(:ticket) }

  context 'when given ticket’s owner' do
    let(:user) { record.owner }

    it { is_expected.not_to permit_actions(%i[show full]) }

    context 'when owner has ticket.agent permission' do

      let(:user) do
        create(:agent, groups: [record.group]).tap do |user|
          record.update!(owner: user)
        end
      end

      it { is_expected.to permit_actions(%i[show full]) }
    end
  end

  context 'when given user that is agent and customer' do
    let(:user) { create(:agent_and_customer, groups: [record.group]) }

    it { is_expected.to permit_actions(%i[show full]) }
  end

  context 'when given a user that is neither owner nor customer' do
    let(:user) { create(:agent) }

    it { is_expected.not_to permit_actions(%i[show full]) }

    context 'but the user is an agent with full access to ticket’s group' do
      before { user.group_names_access_map = { record.group.name => 'full' } }

      it { is_expected.to permit_actions(%i[show full]) }
    end

    context 'but the user is a customer from the same organization as ticket’s customer' do
      let(:record) { create(:ticket, customer: customer) }
      let(:customer) { create(:customer, organization: create(:organization)) }
      let(:user) { create(:customer, organization: customer.organization) }

      context 'and organization.shared is true (default)' do

        it { is_expected.to permit_actions(%i[show full]) }
      end

      context 'but organization.shared is false' do
        before { customer.organization.update(shared: false) }

        it { is_expected.not_to permit_actions(%i[show full]) }
      end
    end

    context 'when user is admin with group access' do
      let(:user) { create(:user, roles: Role.where(name: %w[Admin])) }

      it { is_expected.not_to permit_actions(%i[show full]) }
    end
  end

  context 'when user is agent' do

    context 'when owner has ticket.agent permission' do

      let(:user) do
        create(:agent, groups: [record.group]).tap do |user|
          record.update!(owner: user)
        end
      end

      it { is_expected.to permit_actions(%i[show full]) }
    end

  end
end
