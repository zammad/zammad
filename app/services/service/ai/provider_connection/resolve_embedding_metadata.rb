# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Resolves the embedding metadata of one model - the dimensions of its vectors and its input
# token limit - so the connection dialog can fill both fields without the admin having to
# research them: what the provider itself reports about the model wins, the shared table of
# known defaults stands in, and a value neither source knows stays nil, which the dialog
# answers with a required manual field.
#
# For a model picked from the dropdown the dialog already holds both values, because the model
# listing descriptors carry them in the one listing request (see Concerns::ListsModels). This
# service answers for the rest: a provider serving per-model metadata outside its listing
# (Ollama's /api/show), a manually entered model, and a provider without a listing.
#
# The service only resolves; the dialog persists the values into config[:embedding_size] and
# config[:embedding_input_limit], which Service::AI::VectorDB::CreateTable and
# AI::Provider#embedding_input_limit already consume.
class Service::AI::ProviderConnection::ResolveEmbeddingMetadata < Service::Base
  include Service::AI::ProviderConnection::Concerns::ResolvesEffectiveConfig

  attr_reader :provider, :model, :incoming_config, :existing_config, :related_object

  # incoming_config may contain mask sentinels (restored from existing_config);
  # nil means no config was submitted, so the stored config is resolved against.
  #
  # related_object is the connection being edited, so its HTTP logs can be attributed to it. It is
  # nil while a connection is created, because the record does not exist yet.
  def initialize(provider:, model:, incoming_config: nil, existing_config: {}, related_object: nil)
    @provider        = provider
    @model           = model
    @incoming_config = incoming_config
    @existing_config = existing_config.to_h
    @related_object  = related_object
  end

  # @return [Hash] embedding_size and embedding_input_limit, each an Integer - or nil when no
  #   source knows the model, meaning the admin has to provide the value
  def execute
    klass = AI::Provider.by_name(provider) if provider.present?
    raise Exceptions::UnprocessableContent, __('Unknown provider') if klass.nil?
    raise Exceptions::UnprocessableContent, __('This provider does not support embeddings.') if !klass.supports_embeddings?
    raise Exceptions::UnprocessableContent, __('Missing embedding model in the provider configuration') if model.blank?

    reported = reported_metadata(klass)

    {
      embedding_size:        reported[:embedding_size] || klass.known_embedding_default(:EMBEDDING_SIZES, model),
      embedding_input_limit: reported[:embedding_input_limit] || klass.known_embedding_default(:EMBEDDING_INPUT_LIMITS, model),
    }
  end

  private

  # Best effort: the credentials were already validated by the time the dialog asks for metadata,
  # and a provider that cannot answer the request must not take the dialog down - the shared
  # table (or the admin) still can. URI::Error stands for a malformed URL, which raises out of
  # UserAgent before its own rescue.
  def reported_metadata(klass)
    klass.embedding_model_metadata(effective_config, model, related_object:)
  rescue AI::Provider::RequestError, AI::Provider::ResponseError, URI::Error => e
    Rails.logger.info { "AI provider '#{provider}' could not report embedding metadata for '#{model}': #{e.message}" }

    {}
  end
end
