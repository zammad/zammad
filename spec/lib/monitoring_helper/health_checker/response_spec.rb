# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MonitoringHelper::HealthChecker::Response do
  let(:instance) { described_class.new }

  describe '#merge' do
    it 'adds issues from another response' do
      other_response = described_class.new
      other_response.issues << :another_response

      instance.issues << :former_response
      instance.merge(other_response)

      expect(instance.issues).to match_array(%i[another_response former_response])
    end

    it 'adds actions from another response' do
      other_response = described_class.new
      other_response.actions << :another_response

      instance.actions << :former_response
      instance.merge(other_response)

      expect(instance.actions).to match_array(%i[another_response former_response])
    end
  end

  it '#issues is Array' do
    expect(instance.issues).to be_instance_of(Array)
  end

  it '#actions is Set' do
    expect(instance.actions).to be_instance_of(Set)
  end
end
