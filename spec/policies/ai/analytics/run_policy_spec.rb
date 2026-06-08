# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe AI::Analytics::RunPolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:record)         { create(:ai_analytics_run, related_object:) }
  let(:related_object) { nil }

  context 'when user is agent' do
    let(:user) { create(:agent) }

    context 'when related object is ticket' do
      let(:related_object) { create(:ticket, group:) }
      let(:group)          { create(:group) }

      before { user.groups << group }

      it { is_expected.to permit_all_actions }
    end

    context 'when no related object' do
      it { is_expected.to permit_all_actions }
    end
  end

  context 'when user is customer' do
    let(:user) { create(:customer) }

    context 'when related object is ticket' do
      let(:related_object) { create(:ticket, customer: user) }

      it { is_expected.to forbid_all_actions }
    end

    context 'when no related object' do
      it { is_expected.to forbid_all_actions }
    end
  end
end
