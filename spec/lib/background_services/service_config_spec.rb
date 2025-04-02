# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe BackgroundServices::ServiceConfig do
  let(:sample_service_class) { BackgroundServices::Service::ProcessDelayedJobs }

  describe '#enabled?' do
    it 'enabled if not disabled' do
      instance = described_class.new(service: sample_service_class, disabled: false, workers: 0)
      expect(instance).to be_enabled
    end

    it 'not enabled if disabled' do
      instance = described_class.new(service: sample_service_class, disabled: true, workers: 0)
      expect(instance).not_to be_enabled
    end
  end

  describe '#start_as' do
    it 'fork when workers number is set' do
      instance = described_class.new(service: sample_service_class, disabled: false, workers: 123)
      expect(instance.start_as).to be(:fork)
    end

    it 'thread when workers not set' do
      instance = described_class.new(service: sample_service_class, disabled: false, workers: 0)
      expect(instance.start_as).to be(:thread)
    end
  end

  describe '#workers' do
    it 'returns number capped to max workers' do
      allow(sample_service_class).to receive(:max_workers).and_return(90)
      instance = described_class.new(service: sample_service_class, disabled: false, workers: 123)
      expect(instance.workers).to be(90)
    end
  end

  describe '.configuration_from_env' do
    it 'returns configurations for all known services' do
      configurations = described_class.configuration_from_env({})

      expect(configurations.map(&:service)).to contain_exactly(
        BackgroundServices::Service::ManageSessionsJobs,
        BackgroundServices::Service::ProcessScheduledJobs,
        BackgroundServices::Service::ProcessSessionsJobs,
        BackgroundServices::Service::ProcessDelayedJobs
      )
    end

    it 'parses configuration for a service' do
      hash = { 'ZAMMAD_PROCESS_DELAYED_JOBS_WORKERS' => 12 }

      configurations = described_class.configuration_from_env(hash)
      single_config = configurations.find { |config| config.service == sample_service_class }

      expect(single_config.workers).to be(12)
    end

    it 'handles the deprecated setting ZAMMAD_SESSION_JOBS_CONCURRENT correctly', :aggregate_failures do
      allow(ActiveSupport::Deprecation).to receive(:warn)
      hash = { 'ZAMMAD_SESSION_JOBS_CONCURRENT' => 2 }

      configurations = described_class.configuration_from_env(hash)
      single_config = configurations.find { |config| config.service == BackgroundServices::Service::ProcessSessionsJobs }

      expect(single_config.workers).to be(2)
      expect(ActiveSupport::Deprecation).to have_received(:warn).once
    end
  end

  describe '.single_configuration_from_env' do
    def run(hash)
      described_class.single_configuration_from_env(sample_service_class, hash)
    end

    it 'takes disabled value when true' do
      hash = {
        'ZAMMAD_PROCESS_DELAYED_JOBS_DISABLE' => true,
      }

      expect(run(hash).disabled).to be_truthy
    end

    it 'takes disabled value when false' do
      hash = {
        'ZAMMAD_PROCESS_DELAYED_JOBS_DISABLE' => 0,
      }

      expect(run(hash).disabled).to be(false)
    end

    it 'missing disabled value taken as false' do
      expect(run({}).disabled).to be(false)
    end

    it 'takes workers count' do
      hash = {
        'ZAMMAD_PROCESS_DELAYED_JOBS_WORKERS' => 12,
      }

      expect(run(hash).workers).to be(12)
    end

    it 'missing workers count taken as 0' do
      expect(run({}).workers).to be(0)
    end
  end
end
