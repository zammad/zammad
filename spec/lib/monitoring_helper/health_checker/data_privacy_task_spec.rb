# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MonitoringHelper::HealthChecker::DataPrivacyTask do
  let(:instance) { described_class.new }
  let(:task1)    { create(:data_privacy_task, deletable: create(:agent), state: 'completed', updated_at: 1.hour.ago) }
  let(:task2)    { create(:data_privacy_task, deletable: create(:agent), state: 'wip', updated_at: 1.hour.ago) }
  let(:task3)    { create(:data_privacy_task, deletable: create(:agent), state: 'wip', updated_at: 1.minute.ago) }

  describe '#check_health' do
    it 'adds issue for stuck task' do
      task2
      expect(instance.check_health.issues.first).to match %r{Stuck data privacy task}
    end
  end

  describe '#scope' do
    it 'finds incomplete tasks started before timeout' do
      task1 && task2 && task3

      expect(instance.send(:scope)).to match_array [task2]
    end
  end
end
