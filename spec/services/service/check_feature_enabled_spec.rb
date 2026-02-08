# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::CheckFeatureEnabled do
  subject(:service) { described_class.new(name:, exception:, custom_error_message:, custom_exception_class:) }

  let(:name)                   { 'system_online_service' }
  let(:exception)              { true }
  let(:custom_error_message)   { nil }
  let(:custom_exception_class) { nil }

  before do
    Setting.set(name, value)
  end

  describe '#execute' do
    context 'when raising default exception' do
      context 'when feature is disabled' do
        let(:value) { false }

        it 'raises FeatureDisabledError' do
          expect { service.execute }
            .to raise_error(described_class::FeatureDisabledError, 'This feature is not enabled.')
        end
      end

      context 'when feature is enabled' do
        let(:value) { true }

        it 'returns true' do
          expect(service.execute).to be_nil
        end
      end
    end

    context 'when no exception' do
      let(:exception) { false }

      context 'when feature is disabled' do
        let(:value) { false }

        it 'returns false' do
          expect(service.execute).to be(false)
        end
      end

      context 'when feature is enabled' do
        let(:value) { true }

        it 'returns true' do
          expect(service.execute).to be(true)
        end
      end
    end

    context 'when custom exception class is provided' do
      let(:custom_exception_class) { Exceptions::Forbidden }

      context 'when feature is disabled' do
        let(:value) { false }

        it 'raises the custom exception' do
          expect { service.execute }
            .to raise_error(Exceptions::Forbidden, 'This feature is not enabled.')
        end
      end

      context 'when feature is enabled' do
        let(:value) { true }

        it 'passes' do
          expect(service.execute).to be_nil
        end
      end
    end

    context 'when custom error message is provided' do
      let(:custom_error_message) { 'Custom feature disabled message.' }

      context 'when feature is disabled' do
        let(:value) { false }

        it 'raises FeatureDisabledError with custom message' do
          expect { service.execute }
            .to raise_error(described_class::FeatureDisabledError, 'Custom feature disabled message.')
        end
      end

      context 'when feature is enabled' do
        let(:value) { true }

        it 'passes' do
          expect(service.execute).to be_nil
        end
      end
    end

    context 'when both custom exception class and custom error message are provided' do
      let(:custom_exception_class) { Exceptions::Forbidden }
      let(:custom_error_message)   { 'Custom forbidden message.' }

      context 'when feature is disabled' do
        let(:value) { false }

        it 'raises the custom exception with custom message' do
          expect { service.execute }
            .to raise_error(Exceptions::Forbidden, 'Custom forbidden message.')
        end
      end

      context 'when feature is enabled' do
        let(:value) { true }

        it 'passes' do
          expect(service.execute).to be_nil
        end
      end
    end

    context 'when exception is set to :on_enabled' do
      let(:exception)            { :on_enabled }
      let(:custom_error_message) { 'This cannot be enabled!' }

      context 'when feature is enabled' do
        let(:value) { true }

        it 'raises FeatureDisabledError' do
          expect { service.execute }
            .to raise_error(described_class::FeatureDisabledError, 'This cannot be enabled!')
        end
      end

      context 'when feature is disabled' do
        let(:value) { false }

        it 'passes' do
          expect(service.execute).to be_nil
        end
      end
    end
  end
end
