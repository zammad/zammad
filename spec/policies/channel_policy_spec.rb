# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe ChannelPolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:record) { create(:channel, area: area) }
  let(:area)   { 'Email::Account' }

  context 'when user is admin' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(:show, :create, :update, :destroy) }
  end

  context 'when user is not admin with limited channel permissions' do
    let(:role) { create(:role, permission_names: %w[admin.channel_email]) }
    let(:user) { create(:user, roles: [role]) }

    context 'when user permission matches record' do
      it { is_expected.to permit_actions(:show, :create, :update, :destroy) }
    end

    context 'when user permission does not match record' do
      let(:area) { 'Facebook::Account' }

      it { is_expected.to forbid_actions(:show, :create, :update, :destroy) }
    end
  end

  context 'when user is not admin' do
    let(:user) { create(:agent) }

    it { is_expected.to forbid_actions(:show, :create, :update, :destroy) }
  end
end
