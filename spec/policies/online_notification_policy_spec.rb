# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe OnlineNotificationPolicy do
  subject { described_class.new(user, record) }

  let(:user) { create(:admin) }

  context 'when user is owner' do
    let(:record,) { create(:online_notification, user: user) }

    it { is_expected.to permit_actions(%i[show destroy update]) }
  end

  context 'when user is not owner' do
    let(:record) { create(:online_notification, user: create(:user)) }

    it { is_expected.to forbid_actions(%i[show destroy update]) }
  end
end
