# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MonitoringHelper::HealthChecker do
  let(:instance) { described_class.new }

  def sample_backend(issue)
    Class.new(MonitoringHelper::HealthChecker::Backend) do
      define_method(:check_health) do
        response = MonitoringHelper::HealthChecker::Response.new
        response.issues << issue
        response
      end
    end
  end

  describe '#check_health' do
    it 'returns merged responses' do
      allow(instance).to receive(:backends).and_return([sample_backend('issue1'), sample_backend('issue2')])

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

      allow(instance).to receive_messages(healthy?: false, response: response)
      expect(instance.message).to eq 'issue1;issue2'
    end
  end

  def build_response(issues = [])
    response = MonitoringHelper::HealthChecker::Response.new
    response.issues.concat(issues)
    response
  end
end
