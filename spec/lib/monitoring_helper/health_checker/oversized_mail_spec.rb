# Copyright (C) 2023-2023 Intevation GmbH, https://intevation.de/

require 'rails_helper'

RSpec.describe MonitoringHelper::HealthChecker::OversizedMail do
  let(:instance)  { described_class.new }
  let(:folder)    { SecureRandom.hex }
  let(:directory) { Rails.root.join('tmp', folder) }

  before { stub_const('Channel::EmailParser::OVERSIZED_MAIL_DIRECTORY', directory) }
  after { FileUtils.rm_r(directory) if File.exist?(directory) }

  describe '#check_health' do
    it 'does nothing if directory missing' do
      expect(instance.check_health.issues).to be_blank
    end

    it 'does nothing if no matching files' do
      FileUtils.mkdir_p directory
      FileUtils.touch("#{directory}/test.not.email")

      expect(instance.check_health.issues).to be_blank
    end

    it 'adds issue if oversized mails found' do
      FileUtils.mkdir_p directory
      FileUtils.touch("#{directory}/test.not.email")
      FileUtils.touch("#{directory}/test.eml")

      expect(instance.check_health.issues.first).to eq 'oversized mails: 1'
    end
  end
end
