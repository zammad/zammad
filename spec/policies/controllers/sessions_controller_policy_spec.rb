# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Controllers::SessionsControllerPolicy do
  subject { described_class.new(user, record) }

  let(:record) { SessionsController.new }

  context 'when user has the admin.user permission only' do
    let(:role) { create(:role, permission_names: %w[admin.user]) }
    let(:user) { create(:user, roles: [role]) }

    it { is_expected.to permit_actions(:switch_to_user) }
    it { is_expected.to forbid_actions(:list, :delete) }
  end

  context 'when user has the admin.session permission only' do
    let(:role) { create(:role, permission_names: %w[admin.session]) }
    let(:user) { create(:user, roles: [role]) }

    it { is_expected.to permit_actions(:list, :delete) }
    it { is_expected.to forbid_actions(:switch_to_user) }
  end

  context 'when user is admin' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(:switch_to_user, :list, :delete) }
  end

  context 'when user is agent' do
    let(:user) { create(:agent) }

    it { is_expected.to forbid_actions(:switch_to_user, :list, :delete) }
  end

  context 'when SessionsPolicy decides against impersonation' do
    let(:user) { create(:admin) }

    before do
      allow(SessionsPolicy).to receive(:new).with(user, Sessions).and_return(instance_double(SessionsPolicy, impersonate?: false))
    end

    it { is_expected.to forbid_actions(:switch_to_user) }
  end
end
