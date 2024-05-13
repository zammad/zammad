# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe TokenPolicy do
  subject(:token_policy) { described_class.new(user, record) }

  context 'when token is visible in frontend' do
    let(:record) { create(:token) }

    context 'when token is owned by the same user' do
      let(:user) { record.user }

      it { is_expected.to permit_action(:destroy) }
    end

    context 'when token is owned by another user' do
      let(:user) { create(:user) }

      it { is_expected.to forbid_action(:destroy) }
    end
  end

  context 'when token is not visible in frontend' do
    let(:record) { create(:token, action: :nonapi) }
    let(:user)   { record.user }

    it { is_expected.to forbid_action(:destroy) }
  end
end
