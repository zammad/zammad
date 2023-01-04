# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe DataPrivacyTaskPolicy do
  subject { described_class.new(user, record) }

  let(:record) { create(:data_privacy_task) }

  context 'when user is admin' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(:show) }
  end

  context 'when user is agent' do
    let(:user) { create(:agent) }

    it { is_expected.to forbid_actions(:show) }
  end
end
