# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe AI::AgentPolicy do
  subject { described_class.new(user, record) }

  let(:record) { create(:ai_agent) }

  context 'when user is admin' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(:show, :create, :update, :destroy) }

    context 'when AI agent is not active' do
      before { record.update! active: false }

      it { is_expected.to permit_actions(:show, :create, :update, :destroy) }
    end
  end

  context 'when user is agent' do
    let(:user)  { create(:agent) }

    it { is_expected.to forbid_actions(:show, :create, :update, :destroy) }
  end

  context 'when user is customer' do
    let(:user) { create(:customer) }

    it { is_expected.to forbid_actions(:show, :create, :update, :destroy) }
  end
end
