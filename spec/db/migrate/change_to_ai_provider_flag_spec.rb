# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ChangeToAIProviderFlag, type: :db_migration do
  before do
    Setting
      .find_by!(name: 'ai_provider')
      .destroy!

    Setting.new(
      title:       __('AI provider'),
      name:        'ai_provider',
      area:        'AI::Provider',
      description: __('Stores the AI provider.'),
      options:     {},
      state:       '',
      preferences: {
        authentication: true,
        permission:     ['admin.ai_provider'],
        validations:    [
          'Setting::Validation::AIProvider',
        ],
      },
      frontend:    true,
    ).save(validate: false)
  end

  shared_examples 'migrates ai provider setting' do
    it 'setting does not have validations anymore' do
      expect { migrate }
        .to change { Setting.find_by(name: 'ai_provider').preferences[:validations] }
        .to(nil)
    end

    it 'Changes description' do
      expect { migrate }
        .to change { Setting.find_by(name: 'ai_provider').description }
    end
  end

  context 'when provider was configured' do
    before do
      Setting.set('ai_provider', 'example', validate: false)
      Setting.set('ai_provider_config', { test: 'value' }, validate: false)
    end

    it 'moves provider to ai_provider_config setting' do
      expect { migrate }
        .to change { Setting.get('ai_provider_config') }
        .to include(provider: 'example', test: 'value')
    end

    it 'sets ai_provider flag to true' do
      expect { migrate }
        .to change { Setting.get('ai_provider') }
        .to(true)
    end

    include_examples 'migrates ai provider setting'
  end

  context 'when provider was empty' do
    it 'keeps ai_provider_config setting empty' do
      expect { migrate }
        .not_to change { Setting.get('ai_provider_config') }
        .from({})
    end

    it 'sets ai_provider flag to false' do
      expect { migrate }
        .to change { Setting.get('ai_provider') }
        .to(false)
    end

    include_examples 'migrates ai provider setting'
  end
end
