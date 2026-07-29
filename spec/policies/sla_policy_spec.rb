# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe SlaPolicy do
  subject(:policy) { described_class.new(user, nil) }

  context 'when user is admin' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(%i[show]) }
  end

  context 'when user is an agent' do
    let(:user) { create(:agent) }

    it { is_expected.to forbid_actions(%i[show]) }
  end

  context 'when user is a customer' do
    let(:user) { create(:customer) }

    it { is_expected.to forbid_actions(%i[show]) }
  end
end
