# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe SettingPolicy do
  subject { described_class.new(user, record) }

  let(:role) { create(:role).tap { it.permission_grant('admin.branding') } }

  context 'when setting is protected' do
    let(:record) { build(:setting, preferences: { permission: ['admin'], protected: true }) }

    context 'when user is admin' do
      let(:user) { create(:admin) }

      it { is_expected.to forbid_actions(:show, :update) }
    end
  end

  context 'when setting requires a permission' do
    let(:record) { build(:setting, preferences: { permission: ['admin.branding'] }) }

    context 'when user is admin' do
      let(:user) { create(:admin) }

      it { is_expected.to permit_actions(:show, :update) }
    end

    context 'when user has the permission' do
      let(:user) { create(:user, roles: [role]) }

      it { is_expected.to permit_actions(:show, :update) }
    end

    context 'when user has another admin permission' do
      let(:user) { create(:user, roles: [create(:role).tap { it.permission_grant('admin.text_module') }]) }

      it { is_expected.to forbid_actions(:show, :update) }
    end
  end

  context 'when setting has no permission' do
    let(:record) { build(:setting, preferences: {}) }

    context 'when user is admin' do
      let(:user) { create(:admin) }

      it { is_expected.to permit_actions(:show, :update) }
    end

    context 'when user has a partial admin permission' do
      let(:user) { create(:user, roles: [role]) }

      it { is_expected.to forbid_actions(:show, :update) }
    end
  end

  context 'when setting has an empty permission list' do
    let(:record) { build(:setting, preferences: { permission: [] }) }

    context 'when user is admin' do
      let(:user) { create(:admin) }

      it { is_expected.to forbid_actions(:show, :update) }
    end
  end
end
