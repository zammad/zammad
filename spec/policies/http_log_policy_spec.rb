# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe HttpLogPolicy do
  subject { described_class.new(user, record) }

  let(:record) { create(:http_log, facility: 'GitHub') }

  let(:user) { create(:user, roles: [admin_role]) }

  context 'when user is admin with admin.overview permission' do
    let(:admin_role) { create(:role, permission_names: ['admin.overview']) }

    it { is_expected.to forbid_actions(:show, :create) }
  end

  context 'when user is admin with facility specific permission' do
    let(:admin_role) { create(:role, permission_names: ['admin.integration']) }

    it { is_expected.to permit_actions(:show, :create) }
  end

  context 'when user is admin without relevant permission' do
    let(:admin_role) { create(:role, permission_names: ['admin.webhook']) }

    it { is_expected.to forbid_actions(:show, :create) }
  end

  context 'when user is admin with wildcard permission' do
    let(:admin_role) { create(:role, permission_names: ['admin']) }

    it { is_expected.to permit_actions(:show, :create) }
  end
end
