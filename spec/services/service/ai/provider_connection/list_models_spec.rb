# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::ProviderConnection::ListModels do
  describe '#execute' do
    # Both defaults of the provider are among them, which is what makes them defaults the dialog
    # gets to hear about at all.
    let(:models) do
      [
        { id: 'gpt-4.1', capabilities: [:chat] },
        { id: 'text-embedding-3-small', capabilities: [:embedding] },
      ]
    end

    # What the listing answers for the model its empty embedding field falls back to.
    let(:recommended_metadata) do
      {
        embedding_size:        AI::Provider::EMBEDDING_SIZES['text-embedding-3-small'],
        embedding_input_limit: AI::Provider::EMBEDDING_INPUT_LIMITS['text-embedding-3-small'],
      }
    end

    before do
      allow(AI::Provider::OpenAI).to receive(:models).and_return(models)
    end

    it 'returns the models of the provider' do
      expect(described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' }))
        .to eq({ models: models, default_model: 'gpt-4.1', recommended_embedding_model: 'text-embedding-3-small', recommended_embedding_metadata: recommended_metadata })
    end

    # The dialog names what an empty model field falls back to, and the adapter is the only place
    # that knows it - the AIProviders registry the dialog is built from carries no defaults.
    describe 'default model of the provider' do
      it 'answers with the default of the adapter' do
        expect(described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' }))
          .to include(default_model: AI::Provider::OpenAI::DEFAULT_OPTIONS[:model])
      end

      # A custom endpoint serves whatever was deployed there, so there is no default to name and
      # the dialog says so instead of inventing one.
      context 'when the provider has no default model' do
        before do
          allow(AI::Provider::CustomOpenAI).to receive(:models).and_return(models)
        end

        it 'answers with nothing' do
          expect(described_class.execute(provider: 'custom_open_ai', incoming_config: { 'url' => 'http://localhost:1234/v1' }))
            .to include(default_model: nil)
        end
      end
    end

    # A default the endpoint does not serve is no fallback an empty field could stand for: the
    # connection would fail its first request on it, so the listing overrules the adapter and the
    # dialog asks the admin for a model instead of promising one.
    describe 'defaults the listing does not carry' do
      let(:models) { [{ id: 'o3', capabilities: [:chat] }] }

      it 'withholds them, metadata of the recommendation included' do
        expect(described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' }))
          .to include(default_model: nil, recommended_embedding_model: nil, recommended_embedding_metadata: nil)
      end

      # An Ollama with nothing pulled serves nothing - its own defaults included.
      context 'when the listing carries nothing at all' do
        let(:models) { [] }

        it 'withholds them just the same' do
          expect(described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' }))
            .to include(default_model: nil, recommended_embedding_model: nil, recommended_embedding_metadata: nil)
        end
      end
    end

    # Ollama lists a model by name and tag ('bge-m3:latest'), while both defaults name it alone.
    describe 'defaults listed behind a tag' do
      let(:tagged_models) do
        [
          { id: 'mistral-small3.2:latest', capabilities: [:chat] },
          { id: 'bge-m3:latest', capabilities: [:embedding],
            embedding_size: 1024, embedding_input_limit: 8192 },
        ]
      end

      before do
        allow(AI::Provider::Ollama).to receive(:models).and_return(tagged_models)
      end

      # The tagged descriptor is the recommendation's own, so it answers for its numbers as well.
      it 'recognizes them and sizes the recommendation off its descriptor' do
        expect(described_class.execute(provider: 'ollama', incoming_config: { 'url' => 'http://localhost:11434' }))
          .to include(
            default_model:                  'mistral-small3.2',
            recommended_embedding_model:    'bge-m3',
            recommended_embedding_metadata: { embedding_size: 1024, embedding_input_limit: 8192 },
          )
      end
    end

    # The dialog fills its metadata fields for the empty option that stands for the recommendation,
    # and the listing is the one request it has to do so.
    describe 'metadata of the recommended model' do
      let(:metadata) do
        described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' })[:recommended_embedding_metadata]
      end

      it 'answers out of the shared table of known defaults' do
        expect(metadata).to eq(recommended_metadata)
      end

      # The provider knows its own deployment better than a table keyed by model name does.
      context 'when the listing sizes the recommended model itself' do
        let(:models) do
          [{ id: 'text-embedding-3-small', capabilities: [:embedding],
             embedding_size: 512, embedding_input_limit: 1024 }]
        end

        it 'prefers what the provider reported' do
          expect(metadata).to eq({ embedding_size: 512, embedding_input_limit: 1024 })
        end
      end

      # Which the dialog answers with fields the admin has to fill.
      context 'when no source knows the recommended model' do
        let(:models) { [{ id: 'homegrown-embed', capabilities: [:embedding] }] }

        before do
          allow(AI::Provider::OpenAI).to receive(:recommended_embedding_model).and_return('homegrown-embed')
        end

        it 'answers with no numbers rather than invented ones' do
          expect(metadata).to eq({ embedding_size: nil, embedding_input_limit: nil })
        end
      end

      # A custom endpoint serves whatever was deployed there, so its empty option stands for no
      # model at all - and there is nothing to describe.
      context 'when the provider recommends nothing' do
        before do
          allow(AI::Provider::CustomOpenAI).to receive(:models).and_return(models)
        end

        it 'answers with nothing' do
          expect(described_class.execute(provider: 'custom_open_ai', incoming_config: { 'url' => 'http://localhost:1234/v1' }))
            .to include(recommended_embedding_model: nil, recommended_embedding_metadata: nil)
        end
      end
    end

    it 'raises for an unknown provider' do
      expect { described_class.execute(provider: 'does_not_exist', incoming_config: {}) }
        .to raise_error(Exceptions::UnprocessableContent)
    end

    it 'raises without a provider' do
      expect { described_class.execute(provider: nil, incoming_config: {}) }
        .to raise_error(Exceptions::UnprocessableContent)
    end

    # Azure AI's deployment based endpoints and Zammad AI have no model list at all, and their
    # dialog never asks - a request for them is a caller error, not an empty listing.
    context 'with a provider that does not support listing' do
      it 'rejects it without asking the endpoint', :aggregate_failures do
        allow(AI::Provider::ZammadAI).to receive(:models)

        expect { described_class.execute(provider: 'zammad_ai', incoming_config: { 'token' => 'sk' }) }
          .to raise_error(Exceptions::UnprocessableContent, 'This provider does not support model listing.')
        expect(AI::Provider::ZammadAI).not_to have_received(:models)
      end
    end

    it 'propagates the provider error' do
      allow(AI::Provider::OpenAI).to receive(:models).and_raise(AI::Provider::ResponseError, 'boom')

      expect { described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' }) }
        .to raise_error(AI::Provider::ResponseError, 'boom')
    end

    it 'lists with the config that will be stored: mask sentinels restored, blanks dropped' do
      described_class.execute(
        provider:        'open_ai',
        incoming_config: { 'token' => SensitiveParamsHelper::SENSITIVE_MASK, 'model' => '', 'url' => 'https://example.com' },
        existing_config: { 'token' => 'real-token', 'model' => 'gpt-4o' },
      )

      expect(AI::Provider::OpenAI).to have_received(:models)
        .with({ token: 'real-token', url: 'https://example.com' }, related_object: nil)
    end

    it 'lists with the retained config when none was submitted' do
      described_class.execute(provider: 'open_ai', existing_config: { 'token' => 'kept-token' })

      expect(AI::Provider::OpenAI).to have_received(:models).with({ token: 'kept-token' }, related_object: nil)
    end

    it 'lists with an explicitly emptied config as empty, not the retained one' do
      described_class.execute(provider: 'open_ai', incoming_config: {}, existing_config: { 'token' => 'kept-token' })

      expect(AI::Provider::OpenAI).to have_received(:models).with({}, related_object: nil)
    end

    # So the HTTP log of a failed listing points back at the connection the admin is editing.
    it 'attributes the request to the connection being edited' do
      connection = create(:ai_provider_connection, provider: 'open_ai')

      described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' }, related_object: connection)

      expect(AI::Provider::OpenAI).to have_received(:models).with({ token: 'sk' }, related_object: connection)
    end

    # Stepping back and forth in the wizard must not hit the provider on every transition.
    describe 'caching' do
      it 'asks the provider once for the same config' do
        3.times { described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' }) }

        expect(AI::Provider::OpenAI).to have_received(:models).once
      end

      it 'answers a repeated call from the cache' do
        described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' })
        allow(AI::Provider::OpenAI).to receive(:models).and_return([])

        expect(described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' }))
          .to eq({ models: models, default_model: 'gpt-4.1', recommended_embedding_model: 'text-embedding-3-small', recommended_embedding_metadata: recommended_metadata })
      end

      it 'asks again for changed credentials' do
        described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' })
        described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk-other' })

        expect(AI::Provider::OpenAI).to have_received(:models).twice
      end

      # The dialog's config grows between its steps - the model fields travel back in after a
      # Back. The listing depends on the credentials alone, so the grown config must still hit
      # the cache.
      it 'answers from the cache when only non-credential fields differ' do
        described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' })
        described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk', 'model' => 'gpt-4.1', 'embedding_model' => 'text-embedding-3-small' })

        expect(AI::Provider::OpenAI).to have_received(:models).once
      end

      # The catalogue of a hosted vendor changes rarely; the one of a self-hosted endpoint moves
      # under the admin's hands (`ollama pull`, a redeploy) and must not stand for five minutes.
      describe 'expiry per provider' do
        before do
          allow(Rails.cache).to receive(:fetch).and_call_original
        end

        it 'caches a hosted catalogue for five minutes' do
          described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' })

          expect(Rails.cache).to have_received(:fetch).with(anything, expires_in: described_class::CACHE_TTL)
        end

        it 'caches a self-hosted catalogue for 90 seconds only' do
          allow(AI::Provider::Ollama).to receive(:models).and_return([])

          described_class.execute(provider: 'ollama', incoming_config: { 'url' => 'http://localhost:11434' })

          expect(Rails.cache).to have_received(:fetch).with(anything, expires_in: described_class::VOLATILE_CACHE_TTL)
        end

        it 'caches a custom endpoint catalogue for 90 seconds only' do
          allow(AI::Provider::CustomOpenAI).to receive(:models).and_return([])

          described_class.execute(provider: 'custom_open_ai', incoming_config: { 'url' => 'http://localhost:1234/v1' })

          expect(Rails.cache).to have_received(:fetch).with(anything, expires_in: described_class::VOLATILE_CACHE_TTL)
        end
      end

      it 'asks again for another provider with the same credentials' do
        allow(AI::Provider::Anthropic).to receive(:models).and_return([])

        described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' })
        described_class.execute(provider: 'anthropic', incoming_config: { 'token' => 'sk' })

        expect(AI::Provider::Anthropic).to have_received(:models).once
      end

      # A stale error would keep the dialog from picking up an endpoint that came back.
      it 'does not cache a failed listing' do
        allow(AI::Provider::OpenAI).to receive(:models).and_raise(AI::Provider::ResponseError, 'boom')

        2.times do
          suppress(AI::Provider::ResponseError) do
            described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' })
          end
        end

        expect(AI::Provider::OpenAI).to have_received(:models).twice
      end

      # The keys travel through logs and the cache server's keyspace.
      it 'keeps the credentials out of the cache keys', :aggregate_failures do
        allow(Rails.cache).to receive(:fetch).and_call_original
        allow(Rails.cache).to receive(:delete).and_call_original

        described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk-secret' })

        expect(Rails.cache).to have_received(:fetch).with(satisfy { |key| key.exclude?('sk-secret') }, any_args)
        expect(Rails.cache).to have_received(:delete).with(satisfy { |key| key.exclude?('sk-secret') })
      end
    end

    # What the seeding of the embedding model reads (AI::ProviderConnection#seed_recommended_embedding_model):
    # the verdict of the listing the dialog fetched, rather than the listing itself - which is gone
    # by the time an admin who took their time saves.
    describe '.recommendation_unlisted?' do
      # The catalogue entry the listing cached, dropped as its 90 seconds to five minutes are up.
      # The verdict has to outlive it.
      def expire_cached_listing(provider_name, config)
        service = described_class.new(provider: provider_name, incoming_config: config)

        Rails.cache.delete(service.send(:cache_key, service.send(:effective_config)))
      end

      it 'answers no without asking the endpoint when no listing said anything', :aggregate_failures do
        expect(described_class.recommendation_unlisted?(provider: 'open_ai', config: { 'token' => 'sk' })).to be false
        expect(AI::Provider::OpenAI).not_to have_received(:models)
      end

      it 'answers no for a listing that carried the recommendation' do
        described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' })

        expect(described_class.recommendation_unlisted?(provider: 'open_ai', config: { 'token' => 'sk' })).to be false
      end

      # A model the endpoint does not serve is no model to sign a connection up for behind the
      # admin's back, which is why the dialog leaves the field empty for it in the first place.
      context 'when the listing carried models but not the recommendation' do
        let(:models) { [{ id: 'gpt-4.1', capabilities: [:chat] }] }

        it 'answers yes' do
          described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' })

          expect(described_class.recommendation_unlisted?(provider: 'open_ai', config: { 'token' => 'sk' })).to be true
        end

        # The admin who leaves the '-' option selected takes longer over the dialog than the
        # catalogue lives - the save must still know what the dialog was told.
        it 'keeps answering yes once the catalogue itself is gone' do
          described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' })
          expire_cached_listing('open_ai', { 'token' => 'sk' })

          expect(described_class.recommendation_unlisted?(provider: 'open_ai', config: { 'token' => 'sk' })).to be true
        end

        # An `ollama pull` away, and the very next listing says so.
        it 'forgets it once a listing carries the recommendation after all' do
          described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' })
          expire_cached_listing('open_ai', { 'token' => 'sk' })

          allow(AI::Provider::OpenAI).to receive(:models)
            .and_return([{ id: 'text-embedding-3-small', capabilities: [:embedding] }])
          described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' })

          expect(described_class.recommendation_unlisted?(provider: 'open_ai', config: { 'token' => 'sk' })).to be false
        end

        it 'answers no for credentials no listing was fetched for' do
          described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' })

          expect(described_class.recommendation_unlisted?(provider: 'open_ai', config: { 'token' => 'sk-other' })).to be false
        end

        # A Zammad upgrade can change what a provider recommends, and the verdict on the previous
        # recommendation says nothing about the new one.
        it 'answers no for a recommendation the listing was never asked about' do
          described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' })
          allow(AI::Provider::OpenAI).to receive(:recommended_embedding_model).and_return('text-embedding-4-tiny')

          expect(described_class.recommendation_unlisted?(provider: 'open_ai', config: { 'token' => 'sk' })).to be false
        end

        it 'outlives the catalogue it came from' do
          allow(Rails.cache).to receive(:write).and_call_original

          described_class.execute(provider: 'open_ai', incoming_config: { 'token' => 'sk' })

          expect(Rails.cache).to have_received(:write)
            .with(satisfy { |key| key.end_with?('unlisted-embedding-recommendation') }, 'text-embedding-3-small',
                  expires_in: described_class::UNLISTED_RECOMMENDATION_TTL)
        end
      end

      # A custom endpoint serves whatever was deployed there: there is no recommendation to have a
      # verdict on, and the admin names the model or the connection serves no embeddings.
      context 'when the provider recommends nothing' do
        before do
          allow(AI::Provider::CustomOpenAI).to receive(:models).and_return([])
        end

        it 'answers no' do
          described_class.execute(provider: 'custom_open_ai', incoming_config: { 'url' => 'http://localhost:1234/v1' })

          expect(described_class.recommendation_unlisted?(provider: 'custom_open_ai', config: { 'url' => 'http://localhost:1234/v1' })).to be false
        end
      end

    end
  end
end
