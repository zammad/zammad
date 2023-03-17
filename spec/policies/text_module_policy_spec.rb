# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe TextModulePolicy do
  subject { described_class.new(user, record) }

  let(:group) { create(:group) }

  context 'when user is an admin' do
    let(:user) { create(:admin) }

    context 'when record has no limits' do
      let(:record) { create(:text_module) }

      it { is_expected.to permit_action(:show) }
    end

    context 'when record has group limits and user is listed' do
      let(:user) { create(:agent, groups: [group]) }
      let(:record) { create(:text_module, groups: user.groups) }

      it { is_expected.to permit_action(:show) }
    end

    context 'when record has group limits and user is not listed' do
      let(:record) { create(:text_module, groups: [group]) }

      it { is_expected.to permit_action(:show) }
    end
  end

  context 'when user is an agent' do
    let(:user) { create(:agent) }

    context 'when record has no limits' do
      let(:record) { create(:text_module) }

      it { is_expected.to permit_action(:show) }
    end

    context 'when record has group limits and user is listed' do
      let(:user)   { create(:agent, groups: [group]) }
      let(:record) { create(:text_module, groups: user.groups) }

      it { is_expected.to permit_action(:show) }
    end

    context 'when record has group limits and user is not listed' do
      let(:record) { create(:text_module, groups: [group]) }

      it { is_expected.to forbid_action(:show) }
    end
  end
end
