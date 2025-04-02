# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe ChecklistTemplatePolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:record) { build(:checklist_template) }

  context 'when user is an agent' do
    let(:user) { create(:agent) }

    it { is_expected.to permit_actions(:show) }
    it { is_expected.to forbid_actions(:create, :update, :destroy) }
  end

  context 'when user is an admin' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(:show, :create, :update, :destroy) }

    context 'when checklist feature is disabled' do
      before do
        Setting.set('checklist', false)
      end

      it { is_expected.to forbid_actions(:show, :create, :update, :destroy) }
    end
  end

  context 'when user is a customer' do
    let(:user) { create(:customer) }

    it { is_expected.to forbid_actions(:show, :create, :update, :destroy) }
  end
end
