# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MonitoringHelper::HealthChecker::FailedEmail do
  let(:instance) { described_class.new }

  describe '#check_health' do
    it 'does nothing if directory missing' do
      expect(instance.check_health.issues).to be_blank
    end

    it 'adds issue if unprocessable mails found' do
      create(:failed_email)
      expect(instance.check_health.issues.first).to eq 'emails that could not be processed: 1'
    end
  end
end
