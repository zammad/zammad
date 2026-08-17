# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_audit_logs_examples'

RSpec.describe Setting, type: :model do
  subject(:setting) { create(:setting) }

  it_behaves_like 'HasAuditLogs', update_attribute: 'title', update_value: 'Some updated title'

  describe 'audit log masking of sensitive settings' do
    let(:audit_log) { AuditLog.find_by(auditable_type: 'Setting', auditable_id: setting.id, action_type: 'update') }

    before do
      described_class.set('system_init_done', true)
    end

    context 'when the setting name is sensitive' do
      subject(:setting) { create(:setting, name: 'some_secret_setting', state_current: { value: 'initial value' }) }

      it 'masks the values in the snapshots' do
        setting.update!(state_current: { value: 'updated value' })

        expect(audit_log).to have_attributes(
          value_from: include('state_current' => include('value' => SensitiveParamsHelper::SENSITIVE_MASK)),
          value_to:   include('state_current' => include('value' => SensitiveParamsHelper::SENSITIVE_MASK)),
        )
      end
    end

    context 'when the setting name is not sensitive' do
      subject(:setting) { create(:setting, name: 'some_regular_setting', state_current: { value: 'initial value' }) }

      it 'keeps the values in the snapshots' do
        setting.update!(state_current: { value: 'updated value' })

        expect(audit_log).to have_attributes(
          value_from: include('state_current' => include('value' => 'initial value')),
          value_to:   include('state_current' => include('value' => 'updated value')),
        )
      end
    end
  end

  describe '.get' do
    context 'when given a valid Setting#name' do
      it 'returns #state_current[:value]' do
        expect { setting.update(state_current: { value: 'foo' }) }
          .to change { described_class.get(setting.name) }.to('foo')
      end
    end

    context 'when interpolated value was set and cache is still valid' do
      it 'stores interpolated value' do
        create(:setting, name: 'broadcast_test', state: 'test')
        described_class.send(:load) # prewarm cache

        described_class.set('broadcast_test', 'test #{config.fqdn}') # rubocop:disable Lint/InterpolationCheck

        expect(described_class.get('broadcast_test'))
          .to eq("test #{described_class.get('fqdn')}")
      end
    end

    context 'with offending chars in product_name and fqdn (#4355)' do
      before do
        described_class.set('product_name', '<My "Helpdesk">')
        described_class.set('fqdn', 'localhost:8080')
      end

      it 'sanitizes notification_sender value' do
        expect(described_class.get('notification_sender'))
          .to eq('"<My \'\'Helpdesk\'\'>" <noreply@localhost>')
      end
    end
  end

  describe '.set' do
    context 'when given a valid Setting#name' do
      it 'sets #state_current = { value: <arg> }' do
        expect { described_class.set(setting.name, 'foo') }
          .to change { setting.reload.state_current }.to({ 'value' => 'foo' })
      end

      it 'logs the value' do
        allow(described_class.logger).to receive(:info)
        described_class.set(setting.name, 'foo')
        expect(described_class.logger).to have_received(:info).with("Setting.set('#{setting.name}', \"foo\")")
      end
    end

    context 'when given a sensitive Setting#name' do
      subject(:setting) { create(:setting, name: 'my_token') }

      it 'masks the value' do
        allow(described_class.logger).to receive(:info)
        described_class.set(setting.name, 'foo')
        expect(described_class.logger).to have_received(:info).with("Setting.set('#{setting.name}', \"[FILTERED]\")")
      end
    end

    context 'when #preferences hash includes a :cache key' do
      subject(:setting) { create(:setting, preferences: { cache: ['foo'] }) }

      before { Rails.cache.write('foo', 'bar') }

      it 'resets the cache key' do
        expect { described_class.set(setting.name, 'baz') }
          .to change { Rails.cache.read('foo') }.to(nil)
      end
    end
  end

  describe '.reset' do
    context 'when given a valid Setting#name' do
      it 'sets #state_current = { value: <orig> } (via #state_initial[:value])' do
        setting.update(state_initial: { value: 'foo' })
        described_class.set(setting.name, 'bar')

        expect { described_class.reset(setting.name) }
          .to change { setting.reload.state_current }.to({ value: 'foo' })
      end

      it 'logs the value' do
        setting.update(state_initial: { value: 'foo' })
        allow(described_class.logger).to receive(:info)
        described_class.reset(setting.name)
        expect(described_class.logger).to have_received(:info).with("Setting.reset('#{setting.name}', {\"value\" => \"foo\"})")
      end
    end

    context 'when given a sensitive Setting#name' do
      subject(:setting) { create(:setting, name: 'my_token') }

      it 'masks the value' do
        setting.update(state_initial: { value: 'foo' })
        allow(described_class.logger).to receive(:info)
        described_class.reset(setting.name)
        expect(described_class.logger).to have_received(:info).with("Setting.reset('#{setting.name}', \"[FILTERED]\")")
      end
    end

  end

  describe '.cache_valid?' do
    context 'when loading first time' do
      before do
        # ensure no cache checks are set
        described_class.class_variable_set(:@@lookup_at, nil) # rubocop:disable Style/ClassVars
        described_class.class_variable_set(:@@query_cache_key, nil) # rubocop:disable Style/ClassVars
      end

      it 'cache is not valid' do
        expect(described_class).not_to be_cache_valid
      end
    end

    context 'when cache is valid' do
      before do
        # ensure cache is warm
        described_class.send(:load)

        # ensure cache is not touched by broadcasting the new value
        allow_any_instance_of(described_class).to receive(:broadcast_frontend)

        # ensure cache is not re-warmed by the audit log search indexing reading settings
        allow_any_instance_of(AuditLog).to receive(:search_index_update)
      end

      it 'cache is valid' do
        expect(described_class).to be_cache_valid
      end

      it 'cache is still valid after some time' do
        travel 1.minute
        expect(described_class).to be_cache_valid
      end

      context 'when Setting is updated in the same process' do
        before { described_class.set('maintenance_login', 'sample message') }

        it 'cache is not valid' do
          expect(described_class).not_to be_cache_valid
        end
      end

      context 'when Setting updated outside of the process and class variables were not touched' do
        before { described_class.find_by(name: 'maintenance_login').touch }

        it 'cache is seen as valid' do
          expect(described_class).to be_cache_valid
        end

        it 'cache is seen as invalid after some time' do
          travel 1.minute
          expect(described_class).not_to be_cache_valid
        end
      end
    end
  end

  describe 'attributes' do
    describe '#state_initial' do
      subject(:setting) { build(:setting, state: 'foo') }

      it 'is set on creation, based on #state' do
        expect { setting.save }
          .to change(setting, :state_initial).from({}).to({ value: 'foo' })
      end
    end
  end

  describe 'broadcast_frontend' do
    subject(:setting) do
      build(:setting, name: 'broadcast_test', state: value, frontend: frontend)
        .tap { |setting| setting.preferences = { authentication: true } if authentication_required }
    end

    let(:value)                   { 'foo' }
    let(:frontend)                { true }
    let(:authentication_required) { false }

    context 'when setting is non-frontend' do
      let(:frontend) { false }

      it 'does not broadcast' do
        allow(Sessions).to receive(:broadcast)
        setting.save
        expect(Sessions).not_to have_received(:broadcast)
          .with({ data: { name: 'broadcast_test', value: 'foo' }, event: 'config_update' }, 'public')
      end

      it 'does not trigger subscription' do
        allow(Gql::Subscriptions::ConfigUpdates).to receive(:trigger)
        setting.save
        expect(Gql::Subscriptions::ConfigUpdates).not_to have_received(:trigger).with(setting)
      end
    end

    context 'when setting is public' do
      it 'broadcasts to public' do
        allow(Sessions).to receive(:broadcast)
        setting.save
        expect(Sessions).to have_received(:broadcast)
          .with({ data: { name: 'broadcast_test', value: 'foo' }, event: 'config_update' }, 'public')
      end

      it 'triggers subscription' do
        allow(Gql::Subscriptions::ConfigUpdates).to receive(:trigger)
        setting.save
        expect(Gql::Subscriptions::ConfigUpdates).to have_received(:trigger).with(setting)
      end
    end

    context 'when setting requires authentication' do
      let(:authentication_required) { true }

      it 'broadcasts to authenticated only' do
        allow(Sessions).to receive(:broadcast)
        setting.save
        expect(Sessions).to have_received(:broadcast)
          .with({ data: { name: 'broadcast_test', value: 'foo' }, event: 'config_update' }, 'authenticated')
      end

      it 'triggers subscription' do
        allow(Gql::Subscriptions::ConfigUpdates).to receive(:trigger)
        setting.save
        expect(Gql::Subscriptions::ConfigUpdates).to have_received(:trigger).with(setting)
      end
    end

    context 'when setting uses interpolation' do
      let(:value) { 'test #{config.fqdn}' } # rubocop:disable Lint/InterpolationCheck

      it 'broadcasts to authenticated only' do
        allow(Sessions).to receive(:broadcast)

        setting.save

        expect(Sessions)
          .to have_received(:broadcast)
          .with(
            { data: { name: 'broadcast_test', value: "test #{described_class.get('fqdn')}" }, event: 'config_update' },
            'public'
          )
      end

      it 'triggers subscription' do
        allow(Gql::Subscriptions::ConfigUpdates).to receive(:trigger)
        setting.save
        expect(Gql::Subscriptions::ConfigUpdates).to have_received(:trigger).with(setting)
      end
    end
  end

  # A configuration change made while one of the switches was off must not be lost: re-enabling
  # compares what the index holds against what is configured now, rather than assuming a disabled
  # switch means nothing to reconcile.
  describe 'vector index reconcile on a feature switch change', performs_jobs: true do
    let(:connection) do
      create(:ai_provider_connection, :default_embedding, provider: 'open_ai',
                                                          config:   { token: 'a', embedding_model: 'text-embedding-3-small' })
    end

    before do
      connection
      # vectordb_enabled validates against a connection serving embeddings while the AI provider is
      # on, so it is switched on and off again around that - leaving the tests below to toggle from a
      # clean, disabled starting point. #clear_jobs afterwards, because these very saves reconcile
      # too: what they enqueue would otherwise answer for the assertion, and the lock it leaves would
      # have the next enqueue dismissed onto it.
      described_class.set('ai_provider', true)
      described_class.set('vectordb_enabled', true)
      described_class.set('ai_provider', false)

      clear_jobs
    end

    it 'enqueues a rebuild when enabling the AI provider finds the index does not match' do
      expect { described_class.set('ai_provider', true) }.to have_enqueued_job(VectorIndexRebuildJob)
    end

    it 'does not enqueue anything when the index already matches what is configured' do
      described_class.set('ai_provider', true)
      Service::AI::VectorDB::Embedding::Configuration.record_indexed(Service::AI::VectorDB::Embedding::Configuration.current)
      described_class.set('ai_provider', false)
      clear_jobs

      expect { described_class.set('ai_provider', true) }.not_to have_enqueued_job(VectorIndexRebuildJob)
    end

    it 'does not enqueue anything when disabling the AI provider' do
      described_class.set('ai_provider', true)
      clear_jobs

      expect { described_class.set('ai_provider', false) }.not_to have_enqueued_job(VectorIndexRebuildJob)
    end

    # The admin UI posts to /ai/vector_index/sync after flipping this one, but `Setting.set` from the
    # console or the API does not - and the first build has to happen either way.
    context 'when the vector database switch itself is flipped' do
      before do
        described_class.set('ai_provider', true)
        described_class.set('vectordb_enabled', false)

        clear_jobs
      end

      it 'enqueues a rebuild when enabling it finds nothing built' do
        expect { described_class.set('vectordb_enabled', true) }.to have_enqueued_job(VectorIndexRebuildJob)
      end

      it 'does not enqueue anything when disabling it' do
        described_class.set('vectordb_enabled', true)
        clear_jobs

        expect { described_class.set('vectordb_enabled', false) }.not_to have_enqueued_job(VectorIndexRebuildJob)
      end
    end

    it 'survives the setting not existing yet, as during the initial seed run' do
      described_class.find_by(name: 'vectordb_enabled').destroy

      expect { described_class.set('ai_provider', true) }.not_to raise_error
    end
  end

end
