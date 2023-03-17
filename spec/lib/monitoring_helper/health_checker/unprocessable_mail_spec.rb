# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MonitoringHelper::HealthChecker::UnprocessableMail do
  let(:instance)  { described_class.new }
  let(:folder)    { SecureRandom.hex }
  let(:directory) { Rails.root.join('tmp', folder) }

  before { stub_const("#{described_class}::DIRECTORY", directory) }

  describe '#check_health' do
    it 'does nothing if directory missing' do
      expect(instance.check_health.issues).to be_blank
    end

    it 'does nothing if no matching files' do
      FileUtils.mkdir_p directory
      FileUtils.touch("#{directory}/test.not.email")

      expect(instance.check_health.issues).to be_blank
    end

    it 'adds issue if unprocessable mails found' do
      FileUtils.mkdir_p directory
      FileUtils.touch("#{directory}/test.not.email")
      FileUtils.touch("#{directory}/test.eml")

      expect(instance.check_health.issues.first).to eq 'unprocessable mails: 1'
    end
  end
end
