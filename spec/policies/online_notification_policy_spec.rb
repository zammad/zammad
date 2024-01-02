# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe OnlineNotificationPolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:user) { create(:admin, groups: [Ticket.first.group]) }

  context 'when user is owner' do
    let(:record) { create(:online_notification, user: user) }

    it { is_expected.to permit_actions(%i[show destroy update]) }

    it 'returns true for show columns' do
      expect(policy.show?).to a_kind_of(TrueClass)
    end
  end

  context 'when user is owner, but has no access to related object' do
    let(:record) { create(:online_notification, user: user, o: ticket) }
    let(:ticket) { create(:ticket) }

    it { is_expected.to permit_actions(%i[show destroy update]) }

    it 'returns permitted columns' do
      expect(policy.show?).to a_kind_of(ApplicationPolicy::FieldScope)
    end
  end

  context 'when user is not owner' do
    let(:record) { create(:online_notification, user: create(:user)) }

    it { is_expected.to forbid_actions(%i[show destroy update]) }
  end
end
