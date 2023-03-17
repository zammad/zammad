# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe RolePolicy do
  subject { described_class.new(user, record) }

  let(:record) { create(:role) }

  context 'when user is admin' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(:show) }
  end

  context 'when user is agent' do
    let(:user) { create(:agent) }

    context 'when user has access to role' do
      before { user.roles << record }

      it { is_expected.to permit_actions(:show) }
    end

    context 'when user does not have access to role' do
      it { is_expected.to forbid_actions(:show) }
    end
  end
end
