# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Ticket::TimeAccountingPolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:time_accounting_enabled) { true }

  let(:record) { build(:ticket_time_accounting, ticket: ticket) }
  let(:ticket) { create(:ticket) }
  let(:group)  { ticket.group }
  let(:user)   { create(:agent, groups: [group]) }

  before do
    Setting.set('time_accounting', time_accounting_enabled)
  end

  context 'when time accounting is disabled' do
    let(:time_accounting_enabled) { false }

    it { is_expected.to forbid_actions(:create) }
  end

  context 'when time accounting is enabled' do
    it { is_expected.to permit_actions(:create) }
  end

  context 'when user does not have access to the ticket' do
    let(:user) { create(:agent) }

    it { is_expected.to forbid_actions(:create) }
  end

  context 'when user has no access to the ticket by having read permission' do
    let(:user) { create(:agent) }

    before { user.user_groups.create! group: ticket.group, access: 'read' }

    it { is_expected.to forbid_actions(:create) }
  end

  context 'when user has access to the ticket by having create permission' do
    let(:user) { create(:agent) }

    before { user.user_groups.create! group: ticket.group, access: 'create' }

    it { is_expected.to permit_actions(:create) }
  end

  context 'when user has access to the ticket by having change permission' do
    let(:user) { create(:agent) }

    before { user.user_groups.create! group: ticket.group, access: 'change' }

    it { is_expected.to permit_actions(:create) }
  end

  context 'when user has access to the ticket by having customer access' do
    let(:user) { create(:customer) }

    before { ticket.update! customer: user }

    it { is_expected.to forbid_actions(:create) }
  end
end
