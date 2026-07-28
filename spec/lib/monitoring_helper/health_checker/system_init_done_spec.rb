# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MonitoringHelper::HealthChecker::SystemInitDone do
  let(:instance) { described_class.new }

  describe '`#check_health`' do
    it 'does nothing if system setup is completed' do
      Setting.set('system_init_done', true)
      expect(instance.check_health.issues).to be_blank
    end

    it 'adds issue if system setup is not completed' do
      Setting.set('system_init_done', false)

      expect(instance.check_health.issues.first)
        .to eq 'The system setup is not completed.'
    end
  end
end
