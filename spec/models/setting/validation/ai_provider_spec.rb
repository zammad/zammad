# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::AIProvider do
  let(:setting_name)       { 'ai_provider' }
  let(:ai_provider_config) { {} }

  let(:dummy_zammad_ai_config) do
    {
      provider: 'zammad_ai',
      token:    nil,
    }
  end

  before do
    # Disable validation to avoid ping!
    Setting.set('ai_provider_config', ai_provider_config, validate: false)
  end

  shared_examples 'not raising an error' do
    it 'does not raise an error' do
      expect { Setting.set(setting_name, false) }.not_to raise_error
    end
  end

  shared_examples 'raising an error' do
    it 'raises an error' do
      expect { Setting.set(setting_name, true) }
        .to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'with a false value' do
    it_behaves_like 'not raising an error'

    context 'when provider is present' do
      let(:ai_provider_config) { dummy_zammad_ai_config }

      it_behaves_like 'not raising an error'
    end
  end

  context 'with a true value' do
    it_behaves_like 'raising an error'

    context 'when provider configuration is nil' do
      let(:ai_provider_config) { nil }

      it_behaves_like 'raising an error'
    end

    context 'when provider is present' do
      let(:ai_provider_config) { dummy_zammad_ai_config }

      it_behaves_like 'not raising an error'
    end
  end
end
