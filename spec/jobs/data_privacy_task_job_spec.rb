# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The erasure itself is covered in spec/models/data_privacy_task_spec.rb.
RSpec.describe DataPrivacyTaskJob, type: :job do
  describe '#perform' do
    let(:user)  { create(:customer) }
    let!(:task) { create(:data_privacy_task, deletable: user) }

    before do
      Setting.set('system_init_done', true)
    end

    it 'performs the tasks in process', :aggregate_failures do
      described_class.perform_now

      expect(User).not_to exist(user.id)
      expect(task.reload.state).to eq('completed')
    end

    it 'skips tasks that are not in process' do
      task.update_columns(state: 'failed')

      expect { described_class.perform_now }.not_to change { User.exists?(user.id) }.from(true)
    end
  end
end
