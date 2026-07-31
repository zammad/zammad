# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::AIProvider do
  let(:setting_name) { 'ai_provider' }

  shared_examples 'not raising an error' do |value:|
    it 'does not raise an error' do
      expect { Setting.set(setting_name, value) }.not_to raise_error
    end
  end

  shared_examples 'raising an error' do |value:|
    it 'raises an error' do
      expect { Setting.set(setting_name, value) }
        .to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'with a false value' do
    it_behaves_like 'not raising an error', value: false

    context 'when a provider connection is present' do
      before { create(:ai_provider_connection) }

      it_behaves_like 'not raising an error', value: false
    end
  end

  context 'with a true value' do
    it_behaves_like 'raising an error', value: true

    context 'when a provider connection is present' do
      before { create(:ai_provider_connection) }

      it_behaves_like 'not raising an error', value: true
    end

    # On upgrades the validator runs before CreateAIProviderConnections has created the table
    # (Issue5998AIProviderSettingValidation saves the setting earlier in the migration chain).
    context 'when the provider connections table does not exist yet' do
      before { allow(AI::ProviderConnection).to receive(:table_exists?).and_return(false) }

      it_behaves_like 'not raising an error', value: true
    end
  end
end
