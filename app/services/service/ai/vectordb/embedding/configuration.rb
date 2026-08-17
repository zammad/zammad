# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# What a connection embeds with, and whether replacing one with another leaves the index describing
# something else. The single rule behind both halves of the story: the warning an admin gets before a
# change, and the rebuild that follows it.
#
# Two values decide it. The **model** is what identifies the vectors - the same rule the embedding
# cache is keyed by (Service::AI::VectorDB::Embedding::Cache#digest) - so where it is served from is
# deliberately not part of this: moving 'bge-m3' from a self-hosted Ollama to Zammad AI embeds
# against the same model, and charging a full re-index for the move would be the tokens the warning
# exists to save. The **vector length** is not sent to any provider and changes nothing about the
# vectors, but it is what the index mapping is created with (`dense_vector dims:`), and no reload can
# alter that afterwards.
class Service::AI::VectorDB::Embedding::Configuration
  class << self
    # @return [Hash, NilClass] model and size, nil where the connection embeds with nothing
    def of(connection)
      return nil if connection.nil?

      for_provider(provider: connection.provider, config: connection.config)
    end

    # The configuration semantic search runs on right now.
    #
    # @return [Hash, NilClass]
    def current
      of(AI::ProviderConnection.for_embeddings)
    end

    # The same for values that are not stored yet - what a dialog submitted, which is what the
    # warning is decided on before anything is saved.
    #
    # @return [Hash, NilClass]
    def for_provider(provider:, config:)
      klass = AI::Provider.by_name(provider)
      return nil if klass.nil?

      instance = klass.new(config: normalized_config(klass, config))
      model    = instance.embedding_model
      return nil if model.blank?

      { model: model, size: instance.embedding_size }
    end

    # Whether going from one to the other leaves the index holding vectors nothing queries anymore.
    #
    # Ending up with nothing to embed with is no such change: there is nothing to rebuild from, so
    # the index is left standing rather than dropped - clearing the semantic search default turns the
    # feature off, it does not throw the vectors away.
    def changed?(before, after)
      return false if after.nil?

      before != after
    end

    # What the index was last built with, read from the hidden setting rather than from the connection
    # - the two can disagree by design (a config edited or the feature disabled since the last rebuild
    # ran). {} and nil both mean nothing ever built.
    #
    # @return [Hash, NilClass] normalized to the same shape and key types #current returns, so the two
    #   compare equal with plain `==`.
    def indexed
      value = Setting.get('vectordb_indexed_embedding_configuration')
      return nil if value.blank?

      value.symbolize_keys.slice(:model, :size)
    end

    # Only the rebuild job calls this, once the index actually holds what `configuration` describes.
    #
    # @param configuration [Hash, NilClass] the configuration the index was just built (or reloaded)
    #   with; nil/{} record that nothing is built.
    def record_indexed(configuration)
      Setting.set('vectordb_indexed_embedding_configuration', configuration.presence || {})
    end

    private

    # A provider serving a fixed model stores none of its own
    # (AI::ProviderConnection#remove_unconfigurable_embedding_model), so an embedding model that
    # reached the config anyway - carried over from another provider by a dialog or an API call - is
    # dropped here too. Left in, it would answer for the fixed model and describe a configuration
    # the save is about to discard.
    def normalized_config(klass, config)
      config = config.to_h.deep_symbolize_keys

      return config if klass.embedding_model_fallback.blank?

      config.except(:embedding_model)
    end
  end
end
