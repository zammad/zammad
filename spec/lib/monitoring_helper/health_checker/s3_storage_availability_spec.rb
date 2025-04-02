# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MonitoringHelper::HealthChecker::S3StorageAvailability, integration: true do
  let(:instance) { described_class.new }

  before do
    Setting.set('storage_provider', storage_provider)
  end

  describe '#check_health' do

    context 'with storage_provider DB' do
      let(:storage_provider) { 'DB' }

      it 'reports no issue' do
        expect(instance.check_health.issues).to be_blank
      end
    end

    context 'with storage_provider S3' do
      let(:storage_provider) { 'S3' }

      context 'with service present' do
        it 'reports no issue' do
          expect(instance.check_health.issues).to be_blank
        end
      end

      context 'with service missing' do
        before do
          allow(Store::Provider::S3).to receive(:ping?).and_return(false)
        end

        it 'reports an issue' do
          expect(instance.check_health.issues.first).to eq('The Simple Storage Service is not available.')
        end

      end
    end

  end
end
