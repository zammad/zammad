# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe User::OverviewSortingPolicy do
  subject { described_class.new(user1, record) }

  let(:user1)        { create(:user) }
  let(:user2)        { create(:user) }
  let(:record1)      { create(:'user/overview_sorting', user: user1) }
  let(:record2)      { create(:'user/overview_sorting', user: user2) }

  context 'with access to the record' do
    let(:record) { record1 }

    it { is_expected.to permit_actions(%i[show create update destroy]) }
  end

  context 'with no access to the record' do
    let(:record) { record2 }

    it { is_expected.to forbid_actions(%i[show create update destroy]) }
  end
end
