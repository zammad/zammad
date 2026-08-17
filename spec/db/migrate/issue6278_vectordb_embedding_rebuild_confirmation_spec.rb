# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue6278VectorDBEmbeddingRebuildConfirmation, :aggregate_failures, type: :db_migration do
  let(:vectordb_enabled) { Setting.find_by(name: 'vectordb_enabled') }

  before do
    vectordb_enabled.update!(frontend: false, preferences: vectordb_enabled.preferences.except(:authentication))
    Setting.find_by(name: 'vectordb_indexed_embedding_configuration')&.destroy
  end

  it 'performs no action for new systems', system_init_done: false do
    expect { migrate }.not_to raise_error
    expect(Setting.exists?(name: 'vectordb_indexed_embedding_configuration')).to be false
  end

  describe 'serving the vector database switch to the frontend' do
    it 'serves the setting to authenticated sessions' do
      migrate

      expect(vectordb_enabled.reload).to have_attributes(frontend: true)
      expect(vectordb_enabled.reload.preferences).to include(authentication: true)
    end

    it 'keeps the validation it already had' do
      migrate

      expect(vectordb_enabled.reload.preferences[:validations]).to include('Setting::Validation::VectorDB')
    end

    # An install that switched semantic search on and later dropped the connection serving it: nothing
    # turns the setting off in that case, so its own validation no longer passes - and it has nothing
    # to say about a migration that only changes how the setting is delivered.
    context 'when the stored value is no longer backed by an embedding provider' do
      before do
        vectordb_enabled.update_columns(state_current: { value: true })
        Setting.reload
      end

      it 'migrates anyway' do
        expect { migrate }.not_to raise_error

        expect(vectordb_enabled.reload).to have_attributes(frontend: true)
      end
    end
  end

  describe 'recording what the index was built with' do
    it 'creates the setting' do
      migrate

      expect(Setting.get('vectordb_indexed_embedding_configuration')).to eq({})
    end

    it 'does not run twice on a system that already has the setting' do
      migrate

      expect { migrate }.not_to raise_error
    end

    context 'when semantic search was switched on and backed by a configured connection' do
      before do
        create(:ai_provider_connection, :default_embedding, provider: 'open_ai',
                                                            config:   { token: 'a', embedding_model: 'text-embedding-3-small' })
        Setting.set('ai_provider', true)
        Setting.set('vectordb_enabled', true)
      end

      it 'backfills the configuration the index is assumed to already hold' do
        migrate

        expect(Setting.get('vectordb_indexed_embedding_configuration'))
          .to eq('model' => 'text-embedding-3-small', 'size' => AI::Provider::EMBEDDING_SIZES['text-embedding-3-small'])
      end
    end

    context 'when semantic search was switched on but nothing serves embeddings anymore' do
      before do
        Setting.set('vectordb_enabled', true, validate: false)
      end

      it 'leaves the backfill value blank' do
        migrate

        expect(Setting.get('vectordb_indexed_embedding_configuration')).to eq({})
      end
    end

    context 'when the vector database is switched off' do
      before do
        create(:ai_provider_connection, :default_embedding, provider: 'open_ai',
                                                            config:   { token: 'a', embedding_model: 'text-embedding-3-small' })
        Setting.set('ai_provider', true)
      end

      it 'does not backfill a value' do
        migrate

        expect(Setting.get('vectordb_indexed_embedding_configuration')).to eq({})
      end
    end
  end
end
