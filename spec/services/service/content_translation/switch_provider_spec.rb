# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::ContentTranslation::SwitchProvider do
  subject(:service) { described_class.new(provider:, active:) }

  let(:deepl_config) { { 'api_key' => 'secret-key', 'tier' => 'free' } }

  def stored(name)
    Setting.find_by(name:).state_current[:value]
  end

  def state
    %w[content_translation_provider content_translation_service content_translation_ticket_article].map { |name| stored(name) }
  end

  # Without the connection test that storing the configuration runs.
  def activate_deepl
    Setting.set('content_translation_deepl_config', deepl_config, validate: false)

    described_class.execute(provider: 'deepl', active: true)
  end

  describe 'switching a provider on' do
    let(:provider) { 'ai' }
    let(:active)   { true }

    it 'stores the provider and switches both flags on' do
      service.execute

      expect(state).to eq(['ai', true, true])
    end

    context 'with an unknown provider' do
      let(:provider) { 'nope' }

      it 'refuses and changes nothing', :aggregate_failures do
        expect { service.execute }.to raise_error(ActiveRecord::RecordInvalid, %r{Translation service is not supported})
        expect(state).to eq(['', false, false])
      end
    end

    context 'with a provider that lacks its configuration' do
      let(:provider) { 'deepl' }

      it 'refuses and changes nothing', :aggregate_failures do
        expect { service.execute }.to raise_error(ActiveRecord::RecordInvalid, %r{Translation service configuration is incomplete})
        expect(state).to eq(['', false, false])
      end

      context 'when another process has stored the configuration since' do
        before { store_setting_behind_cache('content_translation_deepl_config', deepl_config) }

        it 'switches the provider on' do
          service.execute

          expect(state).to eq(['deepl', true, true])
        end
      end
    end

    context 'with another provider active' do
      let(:provider) { 'ai' }

      before { activate_deepl }

      it 'replaces it and keeps its configuration', :aggregate_failures do
        service.execute

        expect(state).to eq(['ai', true, true])
        expect(Setting.get('content_translation_deepl_config')).to eq(deepl_config)
      end
    end

    # Another thread that refreshes the settings cache in between loads it without the provider,
    # which is not committed yet.
    context 'when the stored provider is not served back while the flags are written' do
      before { allow(Service::ContentTranslation::Backend).to receive(:configured?).and_return(false) }

      it 'switches the provider on' do
        service.execute

        expect(state).to eq(['ai', true, true])
      end
    end

    context 'when a later write fails' do
      before do
        allow(Setting).to receive(:set).and_call_original
        allow(Setting).to receive(:set).with('content_translation_ticket_article', true).and_raise(ActiveRecord::StatementInvalid)
      end

      it 'takes back the earlier ones', :aggregate_failures do
        expect { service.execute }.to raise_error(ActiveRecord::StatementInvalid)
        expect(state).to eq(['', false, false])
        expect(Setting.get('content_translation_provider')).to eq('')
      end
    end
  end

  describe 'switching a provider off' do
    let(:provider) { 'ai' }
    let(:active)   { false }

    context 'with the provider active' do
      before { setup_content_translation(provider: 'ai') }

      it 'removes the provider and switches both flags off' do
        service.execute

        expect(state).to eq(['', false, false])
      end

      # As above, for the flag that is switched off before the provider is removed.
      context 'when the switched off flag is not served back while the provider is removed' do
        before do
          allow(Setting).to receive(:get).and_call_original
          allow(Setting).to receive(:get).with('content_translation_service').and_return(true)
        end

        it 'removes the provider' do
          service.execute

          expect(stored('content_translation_provider')).to eq('')
        end
      end

      context 'when another process has switched over to another provider since' do
        before do
          Setting.set('content_translation_deepl_config', deepl_config, validate: false)
          store_setting_behind_cache('content_translation_provider', 'deepl')
        end

        it 'leaves that provider active' do
          service.execute

          expect(state).to eq(['deepl', true, true])
        end
      end
    end

    context 'with another provider active' do
      before { activate_deepl }

      it 'changes nothing' do
        service.execute

        expect(state).to eq(['deepl', true, true])
      end
    end

    context 'with no provider active' do
      it 'changes nothing' do
        service.execute

        expect(state).to eq(['', false, false])
      end
    end
  end

  # Storing a configuration and switching its provider on check each other. Both wait for the
  # same lock, so that one of two changes made at the same time sees what the other stored.
  describe 'a provider switched on while its configuration is removed', :ensure_threads_exited do
    self.use_transactional_tests = false

    let(:provider) { 'deepl' }
    let(:active)   { true }

    before { Setting.set('content_translation_deepl_config', deepl_config, validate: false) }

    after do
      unset_content_translation
      Setting.reload
    end

    it 'keeps the configuration when the switch is stored first', :aggregate_failures do
      with_uncommitted_concurrent_write(-> { service.execute }) do
        expect { Setting.set('content_translation_deepl_config', {}) }
          .to raise_error(ActiveRecord::RecordInvalid, %r{active translation service cannot be removed})
      end

      expect(stored('content_translation_provider')).to eq('deepl')
      expect(stored('content_translation_deepl_config')).to eq(deepl_config)
    end

    it 'leaves the provider off when the removal is stored first', :aggregate_failures do
      with_uncommitted_concurrent_write(-> { Setting.set('content_translation_deepl_config', {}) }) do
        expect { service.execute }
          .to raise_error(ActiveRecord::RecordInvalid, %r{Translation service configuration is incomplete})
      end

      expect(stored('content_translation_provider')).to eq('')
      expect(stored('content_translation_deepl_config')).to eq({})
    end
  end
end
