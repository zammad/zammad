# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Report::ProfilesPolicy::Scope do
  subject(:scope) { described_class.new(user, original_collection) }

  let(:original_collection) { Report::Profile }

  let(:global_profile) { create(:report_profile) }

  let(:active_role)              { create(:role, active: true) }
  let(:inactive_role)            { create(:role, active: false) }
  let(:profile_with_active_role) { create(:report_profile, roles: [active_role]) }

  before do
    Report::Profile.destroy_all

    global_profile
    profile_with_active_role
    create(:report_profile, roles: [inactive_role])
    create(:report_profile, roles: [create(:role, active: true)])
  end

  describe '#resolve' do
    context 'without user' do
      let(:user) { nil }

      it 'raises authentication error' do
        expect { scope.resolve }.to raise_error %r{Authentication required}
      end
    end

    context 'without reporting permissions' do
      let(:user) { create(:agent) }

      it 'returns nothing' do
        expect(scope.resolve).to be_empty
      end
    end

    context 'with reporting permission' do
      let(:report_permission_role) { create(:role).tap { |r| r.permission_grant('report') } }
      let(:user)                   { create(:agent, roles: [report_permission_role, active_role]) }

      it 'returns global and active-role matching profiles only' do
        expect(scope.resolve).to contain_exactly(global_profile, profile_with_active_role)
      end
    end
  end
end
