# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Ticket::SharedDraftZoomPolicy do
  subject { described_class.new(user, record) }

  let(:ticket) { create(:ticket) }
  let(:record) { create(:ticket_shared_draft_zoom, ticket: ticket) }
  let(:user)   { create(:agent) }

  shared_examples 'access allowed' do
    it { is_expected.to be_update }
    it { is_expected.to be_show }
    it { is_expected.to be_destroy }
  end

  shared_examples 'access denied' do
    it { is_expected.not_to be_update }
    it { is_expected.not_to be_show }
    it { is_expected.not_to be_destroy }
  end

  context 'when user has no tickets access' do
    let(:user) { create(:customer) }

    include_examples 'access denied'
  end

  context 'when user has ticket access' do
    context 'when user has access to the ticket' do
      before do
        user.user_groups.create! group: ticket.group, access: :full
      end

      include_examples 'access allowed'
    end

    context 'when user has read-only access to the ticket' do
      before do
        user.user_groups.create! group: ticket.group, access: :read
      end

      include_examples 'access denied'
    end

    context 'when user has no access to the ticket' do
      before do
        user.user_groups.create! group: create(:group), access: :full
      end

      include_examples 'access denied'
    end
  end
end
