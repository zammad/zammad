# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MonitoringHelper::HealthChecker::ImportMode do
  let(:instance) { described_class.new }

  describe '`#check_health`' do
    it 'does nothing if import_mode is disabled' do
      Setting.set('import_mode', false)
      expect(instance.check_health.issues).to be_blank
    end

    it 'adds issue if import_mode is enabled' do
      Setting.set('import_mode', true)

      expect(instance.check_health.issues.first)
        .to eq 'The instance is running in import_mode - please check the configuration if this is not intended.'
    end
  end
end
