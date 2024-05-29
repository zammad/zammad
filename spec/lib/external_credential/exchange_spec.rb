# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ExternalCredential::Exchange do
  describe '.refresh_token' do
    # https://github.com/zammad/zammad/issues/4454
    context 'when Exchange integration is not configured at all' do
      before do
        Setting.set('exchange_oauth', {})
        Setting.set('exchange_integration', true)
      end

      it 'does always return a value' do
        expect(described_class.refresh_token).to be_truthy
      end
    end

    # https://github.com/zammad/zammad/issues/4961
    context 'when Exchange integration is not enabled' do
      before do
        Setting.set('exchange_integration', false)
      end

      it 'does always return a value' do
        expect(described_class.refresh_token).to be_truthy
      end
    end
  end
end
