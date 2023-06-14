# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Controllers::Ticket::TimeAccountingsControllerPolicy do
  subject { described_class.new(user, record) }

  let(:group)  { ticket.group }
  let(:ticket) { create(:ticket) }

  let(:record_class) { Ticket::TimeAccountingsController }
  let(:record) do
    rec        = record_class.new
    rec.params = { ticket_id: ticket.id }

    rec
  end

  context 'with agent who has update access to ticket' do
    let(:user) { create(:agent) }

    before do
      user.groups << group
    end

    it { is_expected.to forbid_actions(:update, :destroy) }
    it { is_expected.to permit_actions(:index, :show, :create) }
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

    it { is_expected.to permit_actions(:update, :destroy) }
    it { is_expected.to forbid_actions(:index, :show, :create) }
  end
end
