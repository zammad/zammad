# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe DataPrivacyTaskJob, type: :job do

  describe '#perform' do

    before do
      Setting.set('system_init_done', true)
    end

    let!(:organization) { create(:organization, name: 'test') }
    let!(:admin)        { create(:admin) }
    let!(:user)         { create(:customer, organization: organization) }

    it 'checks if the user is deleted' do
      create(:data_privacy_task, deletable: user)
      described_class.perform_now
      expect { user.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'checks if deletion does not crash if the user is already deleted' do
      task = create(:data_privacy_task, deletable: user)
      user.destroy
      described_class.perform_now
      expect(task.reload.state).to eq('completed')
    end

    it 'checks if the organization is deleted' do
      create(:data_privacy_task, deletable: user)
      described_class.perform_now
      expect(organization.reload).to be_a(Organization)
    end

    it 'checks if the state is completed' do
      task = create(:data_privacy_task, deletable: user)
      described_class.perform_now
      expect(task.reload.state).to eq('completed')
    end

    it 'checks if the user is deleted (delete_organization=true)' do
      create(:data_privacy_task, deletable: user, preferences: { delete_organization: 'true' })
      described_class.perform_now
      expect { user.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'checks if the organization is deleted (delete_organization=true)' do
      create(:data_privacy_task, deletable: user, preferences: { delete_organization: 'true' })
      described_class.perform_now
      expect { organization.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'checks if the organization is not deleted (delete_organization=true) if another user was added while task is queued' do
      create(:data_privacy_task, deletable: user, preferences: { delete_organization: 'true' })

      another_user = create(:user)
      another_user.update! organization: organization

      described_class.perform_now
      expect(organization.reload).to be_present
    end

    it 'checks if the organization is removed from secondary organizations for users when deleted (delete_organization=true)', aggregate_failures: true do
      create(:data_privacy_task, deletable: user, preferences: { delete_organization: 'true' })

      another_user = create(:user)
      another_user.organizations << organization

      another_user.assets({}) # make sure cache exists

      described_class.perform_now
      expect { organization.reload }.to raise_error(ActiveRecord::RecordNotFound)

      expect(another_user.assets({}))
        .not_to include(
          User: include(
            another_user.id => include(
              'organization_ids' => include(organization.id)
            )
          )
        )
    end

    it 'checks creation of activity stream log' do
      create(:data_privacy_task, deletable: user, created_by: admin)
      travel 15.minutes
      described_class.perform_now
      expect(admin.activity_stream(20).any? { |entry| entry.type.name == 'completed' }).to be true
    end
  end
end
