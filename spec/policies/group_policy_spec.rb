# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe GroupPolicy do
  subject { described_class.new(user, record) }

  let(:record) { create(:group) }

  context 'when user is admin' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(:show) }
  end

  context 'when user is agent' do
    let(:user) { create(:agent) }

    context 'when user has access to group' do
      before { user.groups << record }

      it { is_expected.to permit_actions(:show) }
    end

    context 'when user does not have access to group' do
      it { is_expected.to forbid_actions(:show) }
    end
  end

  context 'when user is customer' do
    let(:user) { create(:customer) }

    context 'when has ticket in group' do
      before { create(:ticket, group: record, customer: user) }

      it { is_expected.to permit_actions(:show) }
    end

    context 'when has no ticket in a group' do
      it { is_expected.to forbid_actions(:show) }
    end
  end
end
