# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Ticket::SharedDraftZoomPolicy do
  subject { described_class.new(user, record) }

  let(:ticket) { create(:ticket) }
  let(:record) { create(:ticket_shared_draft_zoom, ticket: ticket) }
  let(:user)   { create(:agent) }

  context 'when user has no tickets access' do
    let(:user) { create(:customer) }

    it { is_expected.to forbid_actions(:update, :show, :destroy) }
  end

  context 'when user has ticket access' do
    context 'when user has access to the ticket' do
      before do
        user.user_groups.create! group: ticket.group, access: :full
      end

      it { is_expected.to permit_actions(:update, :show, :destroy) }
    end

    context 'when user has read-only access to the ticket' do
      before do
        user.user_groups.create! group: ticket.group, access: :read
      end

      it { is_expected.to forbid_actions(:update, :show, :destroy) }
    end

    context 'when user has no access to the ticket' do
      before do
        user.user_groups.create! group: create(:group), access: :full
      end

      it { is_expected.to forbid_actions(:update, :show, :destroy) }
    end

    context 'when user is customer of the ticket' do
      let(:user) { ticket.customer }

      it { is_expected.to forbid_actions(:update, :show, :destroy) }
    end
  end
end
