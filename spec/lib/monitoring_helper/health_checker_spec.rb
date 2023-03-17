# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

class Sample1 < MonitoringHelper::HealthChecker::Backend
  def check_health
    response = MonitoringHelper::HealthChecker::Response.new
    response.issues << 'issue1'
    response
  end
end

class Sample2 < MonitoringHelper::HealthChecker::Backend
  def check_health
    response = MonitoringHelper::HealthChecker::Response.new
    response.issues << 'issue2'
    response
  end
end

RSpec.describe MonitoringHelper::HealthChecker do
  let(:instance) { described_class.new }

  describe '#check_health' do
    it 'returns merged responses' do
      allow(instance).to receive(:backends).and_return([Sample1, Sample2])

      expect(instance.check_health.issues).to match_array(%w[issue1 issue2])
    end
  end

  describe '#healthy?' do
    it 'returns true if response has no issues' do
      response = build_response

      allow(instance).to receive(:response).and_return(response)
      expect(instance).to be_healthy
    end

    it 'returns false if response has issues' do
      response = build_response(%w[issue])

      allow(instance).to receive(:response).and_return(response)
      expect(instance).not_to be_healthy
    end
  end

  describe '#message' do
    it 'returns success if healthy' do
      allow(instance).to receive(:healthy?).and_return(true)
      expect(instance.message).to eq 'success'
    end

    it 'returns joined issues if any' do
      response = build_response(%w[issue1 issue2])

      allow(instance).to receive(:healthy?).and_return(false)
      allow(instance).to receive(:response).and_return(response)
      expect(instance.message).to eq 'issue1;issue2'
    end
  end

  def build_response(issues = [])
    response = MonitoringHelper::HealthChecker::Response.new
    response.issues.concat(issues)
    response
  end
end
