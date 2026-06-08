# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue5254UserOrganizationUniqueness, type: :db_migration do
  let(:user1) { prepare_user_with_non_unique_organizations }
  let(:user2) { prepare_user_with_unique_organizations }
  let(:user3) { prepare_user_with_primary_organization }
  let(:user4) { prepare_user_without_organizations }

  context 'when system contains users with non-unique organizations' do
    before do
      user1 && user2 && user3 && user4
    end

    it 'removes non-unique organizations from users' do
      expect { migrate }
        .to change { user1.reload.organizations.include?(user1.organization) }.from(true).to(false)
        .and change(user1, :updated_at)
        .and not_change { user2.reload.organizations.count }.from(3)
        .and not_change { user3.reload.organization }.from(user3.organization)
        .and not_change { user4.reload.organization.nil? }.from(true)
    end
  end

  context 'when system does not contain users with non-unique organizations' do
    before do
      user2 && user3 && user4
    end

    it 'does not touch unique organizations in users' do
      expect { migrate }
        .to  not_change { user2.reload.organizations.count }.from(3)
        .and not_change { user3.reload.organization }.from(user3.organization)
        .and not_change { user4.reload.organization.nil? }.from(true)
    end
  end

  # We have to resort to this long-way round approach of preparing the data, since the migration is designed to fix
  #   an already broken state, which is not possible to be created via the regular factories and associations.
  def prepare_user_with_non_unique_organizations
    organization1 = create(:organization)
    organization2 = create(:organization)
    user = create(:user, organization: organization1, organizations: [organization2])
    user.update_column(:organization_id, organization2.id) # does not trigger callbacks, which is what we want here
    expect(user.organizations).to include(user.organization)
    user
  end

  def prepare_user_with_unique_organizations
    create(:user, organization: create(:organization), organizations: create_list(:organization, 3))
  end

  def prepare_user_with_primary_organization
    create(:user, :with_org)
  end

  def prepare_user_without_organizations
    create(:user)
  end
end
