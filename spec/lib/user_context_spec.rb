# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe UserContext do
  subject(:user_context) { described_class.new(user, token) }

  describe '#permissions?' do
    context 'when user with ticket.agent permission' do
      let(:user)  { create(:user, roles: [create(:role, :agent)]) }
      let(:token) { nil }

      it { is_expected.to be_permissions('ticket.agent') }
      it { is_expected.not_to be_permissions('admin') }
    end

    # https://github.com/zammad/zammad/issues/3186
    context 'when user with ticket.agent permission and token created by user who doesn\'t' do
      let(:user)        { create(:user, roles: [create(:role, :agent)]) }
      let(:token_owner) { create(:user, roles: [create(:role, :admin)]) }
      let(:token)       { create(:token, user: token_owner, preferences: { permission: %w[ticket.agent] }) }

      it { is_expected.to be_permissions('ticket.agent') }
      it { is_expected.not_to be_permissions('admin') }
    end
  end
end
