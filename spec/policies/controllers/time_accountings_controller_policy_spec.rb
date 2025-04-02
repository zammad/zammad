# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Controllers::TimeAccountingsControllerPolicy do
  subject { described_class.new(user, record) }

  let(:group)                   { ticket.group }
  let(:ticket)                  { create(:ticket) }
  let(:time_accounting_enabled) { true }

  let(:record_class) { TimeAccountingsController }
  let(:record) do
    rec        = record_class.new
    rec.params = { ticket_id: ticket.id }

    rec
  end

  before do
    Setting.set 'time_accounting', time_accounting_enabled
  end

  context 'with agent who has update access to ticket' do
    let(:user) { create(:agent, groups: [group]) }

    it { is_expected.to forbid_actions(:update, :destroy) }
    it { is_expected.to permit_actions(:index, :show, :create) }

    context 'when time accounting is disabled' do
      let(:time_accounting_enabled) { false }

      it { is_expected.to forbid_actions(:create) }
      it { is_expected.to permit_actions(:index, :show) }
    end

    context 'when time accounting is not allowed' do
      before do
        allow_any_instance_of(Ticket::TimeAccountingPolicy)
          .to receive(:create?).and_return(false)
      end

      it { is_expected.to forbid_actions(:create) }
      it { is_expected.to permit_actions(:index, :show) }
    end

    context 'when time accounting selector is present and not matching' do
      before do
        allow_any_instance_of(Ticket::TimeAccountingPolicy)
          .to receive(:create?).and_return(true)
      end

      it { is_expected.to permit_actions(:create, :index, :show) }
    end
  end

  context 'with agent who has no access to ticket' do
    let(:user) { create(:agent) }

    it { is_expected.to forbid_actions(:index, :show, :create, :update, :destroy) }
  end

  context 'with agent who has read access to ticket' do
    let(:user) { create(:agent) }

    before do
      user.user_groups.create! group: group, access: 'read'
    end

    it { is_expected.to forbid_actions(:index, :show, :create, :update, :destroy) }
  end

  context 'with admin who has no access to ticket' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(:index, :show, :create, :update, :destroy) }
  end

  context 'with customer who has access to ticket' do
    let(:user) { create(:customer) }

    before do
      ticket.update! customer: user
    end

    it { is_expected.to forbid_actions(:index, :show, :create, :update, :destroy) }
  end
end
