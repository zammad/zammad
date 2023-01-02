# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe OverviewPolicy do
  subject { described_class.new(user, record) }

  let(:record_role) { create(:role) }
  let(:record)      { create(:overview, roles: [record_role]) } # Make sure no default roles are assigned
  let(:user_role)   { create(:role) }
  let(:user)        { create(:user, roles: [user_role]) } # Make sure no default roles are assigned

  context 'with unassigned admin user' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(%i[show create update destroy]) }
    it { is_expected.to forbid_actions(%i[use]) }
  end

  context 'with assigned admin user' do
    let(:record) { create(:overview, roles: [Role.find_by(name: 'Admin')]) }
    let(:user)   { create(:admin) }

    it { is_expected.to permit_actions(%i[use show create update destroy]) }
  end

  context 'with users assigned to the overview' do
    let(:other_user) { create(:user) }
    let(:record)     { create(:overview, users: [other_user]) }

    context 'with user assigned via role, but not directly' do
      let(:record) { create(:overview, users: [other_user], roles: [user_role]) }

      it { is_expected.to forbid_actions(%i[use show create update destroy]) }
    end

    context 'with user assigned directly, but not also via role' do
      let(:other_user) { user }

      it { is_expected.to forbid_actions(%i[use show create update destroy]) }
    end

    context 'with user assigned directly, and also via role' do
      let(:record) { create(:overview, roles: [user_role], users: [user]) }

      it { is_expected.to permit_actions(%i[use show]) }
      it { is_expected.to forbid_actions(%i[create update destroy]) }
    end
  end

  context 'without users assigned to the overview' do
    context 'with user assigned via role' do
      let(:record) { create(:overview, roles: [user_role]) }

      it { is_expected.to permit_actions(%i[use show]) }
      it { is_expected.to forbid_actions(%i[create update destroy]) }
    end

    context 'with user not assigned via role' do
      it { is_expected.to forbid_actions(%i[use show create update destroy]) }
    end

  end

end
