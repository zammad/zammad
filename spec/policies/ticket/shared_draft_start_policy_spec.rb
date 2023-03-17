# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Ticket::SharedDraftStartPolicy do
  subject { described_class.new(user, record) }

  let(:group)  { record.group }
  let(:record) { create(:ticket_shared_draft_start) }
  let(:user)   { create(:agent) }

  shared_examples 'access allowed' do
    it { is_expected.to be_create }
    it { is_expected.to be_update }
    it { is_expected.to be_show }
    it { is_expected.to be_destroy }
  end

  shared_examples 'access denied' do
    it { is_expected.not_to be_create }
    it { is_expected.not_to be_update }
    it { is_expected.not_to be_show }
    it { is_expected.not_to be_destroy }
  end

  context 'when user has no tickets access' do
    let(:user) { create(:customer) }

    include_examples 'access denied'
  end

  context 'when user has ticket access' do
    context 'when draft has same group as user' do
      before do
        user.user_groups.create! group: group, access: :full
      end

      include_examples 'access allowed'
    end

    context 'when draft has same group as user but read-only' do
      before do
        user.user_groups.create! group: group, access: :read
      end

      include_examples 'access denied'
    end

    context 'when draft has one of the groups of the user' do
      before do
        user.user_groups.create! group: group, access: :full
        user.user_groups.create! group: create(:group), access: :full
      end

      include_examples 'access allowed'
    end
  end
end
