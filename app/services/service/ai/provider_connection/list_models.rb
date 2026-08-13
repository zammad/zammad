# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Lists the models a provider endpoint offers for the credentials that would be stored, so the
# connection dialog can offer a dropdown instead of a plain model text field.
class Service::AI::ProviderConnection::ListModels < Service::Base
  include Service::AI::ProviderConnection::Concerns::ResolvesEffectiveConfig

  attr_reader :provider, :incoming_config, :existing_config, :related_object

  # Kept short on purpose: it only has to carry the admin back and forth in the dialog without
  # re-hitting the provider, not to hide a model that was pulled or deployed in the meantime.
  CACHE_TTL = 5.minutes

  # For a provider whose catalogue is under the admin's own control (volatile_model_listing?):
  # `ollama pull` adds a model in seconds and a custom endpoint serves a new one after a
  # redeploy, so the listing goes stale much faster than a hosted vendor's catalogue - long
  # enough to carry the dialog's step transitions, short enough that a fresh model shows up on
  # the next open.
  VOLATILE_CACHE_TTL = 90.seconds

  # How long the listing's verdict on the recommended embedding model outlives the listing that
  # produced it. The catalogue is cached for the dialog and goes stale as fast as an `ollama pull`
  # makes it; the verdict is read by the save that follows (see
  # AI::ProviderConnection#seed_recommended_embedding_model), which arrives after however long the
  # admin spent in the dialog - a dialog left open across a working day included. Expiring with the
  # catalogue would make the seeding forget what the admin was shown and name the model the endpoint
  # was seen not to serve.
  UNLISTED_RECOMMENDATION_TTL = 12.hours

  # What the listing actually depends on: where to ask and how to authenticate. Everything else
  # the dialog posts must stay out of the cache key - its config grows between the steps (the
  # model fields travel back in after a Back), which would otherwise miss the cache on every
  # step transition.
  CREDENTIAL_CONFIG_KEYS = %i[url token].freeze

  # incoming_config may contain mask sentinels (restored from existing_config);
  # nil means no config was submitted, so the stored config is listed against.
  #
  # related_object is the connection being edited, so its HTTP logs can be attributed to it. It is
  # nil while a connection is created, because the record does not exist yet.
  def initialize(provider:, incoming_config: nil, existing_config: {}, related_object: nil)
    @provider        = provider
    @incoming_config = incoming_config
    @existing_config = existing_config.to_h
    @related_object  = related_object
  end

  # @return [Hash] the models the provider offers, the models its empty fields fall back to and
  #   the metadata of the recommended embedding model ({ models:, default_model:,
  #   recommended_embedding_model:, recommended_embedding_metadata: }). Both defaults are nil where
  #   the listing does not carry them (see #listed_model). Provider errors are raised, not
  #   swallowed - the caller decides how a failed listing surfaces.
  def execute
    klass = AI::Provider.by_name(provider) if provider.present?
    raise Exceptions::UnprocessableContent, __('Unknown provider') if klass.nil?

    # Azure AI's deployment based endpoints and Zammad AI have no model list, and their dialog
    # never asks - a request for them is a caller error, not an empty listing.
    raise Exceptions::UnprocessableContent, __('This provider does not support model listing.') if !klass.supports_model_listing?

    models          = cached_models(klass)
    embedding_model = listed_model(klass.recommended_embedding_model, models)

    remember_unlisted_recommendation(klass, embedding_model)

    # The defaults travel with the list because they are what an empty model field amounts to. The
    # adapters are their single source: the dialog names them off this answer rather than off a
    # copy in the AIProviders registry, which drifted from the adapters once already.
    #
    # Both are answered for by the listing, though, not merely accompanied by it: what the endpoint
    # does not serve is no default it could stand for (see #listed_model).
    {
      default_model:                  listed_model(klass.default_model, models),
      recommended_embedding_model:    embedding_model,
      recommended_embedding_metadata: recommended_embedding_metadata(klass, models, embedding_model),
      models:                         models,
    }
  end

  # Whether the last listing for these credentials was seen not to serve the provider's recommended
  # embedding model - the decision the dialog acted on when it offered no model for the empty option
  # ('-' instead of 'Default (text-embedding-3-small)'), carried to the save that follows it. Never
  # asks the endpoint: the caller is a model callback (see
  # AI::ProviderConnection#seed_recommended_embedding_model), which is no place for a provider
  # round-trip.
  #
  # False where no listing said so, which is what a connection created through the API or the
  # console amounts to: nothing is known against the recommendation there, and it stands.
  #
  # @return [Boolean] true when the recommendation was seen missing from the listing
  def self.recommendation_unlisted?(provider:, config:)
    new(provider:, incoming_config: config).recommendation_unlisted?
  end

  def recommendation_unlisted?
    recommendation = AI::Provider.by_name(provider)&.recommended_embedding_model
    return false if recommendation.blank?

    # The remembered model rather than a flag: a Zammad upgrade can change what a provider
    # recommends, and a verdict on the previous recommendation says nothing about the new one.
    Rails.cache.read(unlisted_recommendation_cache_key(effective_config)) == recommendation
  end

  private

  # Remembers a recommendation the endpoint was seen not to serve, so the seeding still knows about
  # it once the catalogue's own 90 seconds to five minutes are up (see UNLISTED_RECOMMENDATION_TTL).
  #
  # Only the negative verdict is kept, and only until a listing carries the recommendation after all
  # (an `ollama pull` away): a positive one needs no memory, because a seeding that knows nothing
  # names the recommendation anyway. So this can only ever withhold a model the provider was seen not
  # to serve, never sign a connection up for one.
  def remember_unlisted_recommendation(klass, listed_recommendation)
    recommendation = klass.recommended_embedding_model
    return if recommendation.blank?

    key = unlisted_recommendation_cache_key(effective_config)

    return Rails.cache.delete(key) if listed_recommendation.present?

    Rails.cache.write(key, recommendation, expires_in: UNLISTED_RECOMMENDATION_TTL)
  end

  # A default of the adapter, as far as the listing backs it: a model the endpoint was seen not to
  # serve is no fallback an empty field could stand for, and naming it would sign the connection up
  # for a model its first request fails on. Withheld instead, so the dialog says the field has no
  # default and asks for a model rather than promising one.
  #
  # @return [String, NilClass] the model, nil for one the listing does not carry
  def listed_model(model, models)
    model if listed_descriptor(model, models)
  end

  # The descriptor the listing carries for a model. Ollama lists a model by name and tag
  # ('bge-m3:latest'), while a default names it alone - so the tag has no say in the comparison.
  #
  # @return [Hash, NilClass] the descriptor, nil for a model the listing does not carry
  def listed_descriptor(model, models)
    return nil if model.blank?

    models.detect { |descriptor| descriptor[:id].to_s.split(':').first == model }
  end

  # The dimensions and the input limit of the recommended model, so the dialog can fill both
  # fields for the empty option that stands for it - a model the admin never picked, and one a
  # request of its own (Service::AI::ProviderConnection::ResolveEmbeddingMetadata) would ask the
  # provider about every time the dialog is opened.
  #
  # What the listing reports for the model wins, the shared table of known defaults stands in, and
  # a value neither knows stays nil - the same order and the same outcome as the resolve service,
  # except without the provider request: the recommendation is one of the listed models by now, so
  # its own descriptor describes it already.
  #
  # @return [Hash, NilClass] the metadata of the recommendation, nil where there is none to describe
  def recommended_embedding_metadata(klass, models, model)
    return nil if model.blank?

    listed = listed_descriptor(model, models) || {}

    {
      embedding_size:        listed[:embedding_size] || klass.known_embedding_default(:EMBEDDING_SIZES, model),
      embedding_input_limit: listed[:embedding_input_limit] || klass.known_embedding_default(:EMBEDDING_INPUT_LIMITS, model),
    }
  end

  # Only a successful listing is cached: an error must not keep the dialog from picking up an
  # endpoint that came back, and a fixed credential lands on a different key anyway.
  def cached_models(klass)
    config = effective_config

    Rails.cache.fetch(cache_key(config), expires_in: cache_ttl(klass)) do
      klass.models(config, related_object:)
    end
  end

  def cache_ttl(klass)
    klass.volatile_model_listing? ? VOLATILE_CACHE_TTL : CACHE_TTL
  end

  # Digest rather than the values: a cache key travels through logs and the cache server's
  # keyspace, which is no place for a provider token.
  def cache_key(config)
    digest = Digest::SHA256.hexdigest(config.slice(*CREDENTIAL_CONFIG_KEYS).sort.to_json)

    "#{self.class.name}/#{provider}/#{digest}"
  end

  # Its own entry rather than a value inside the listing: the two answer for different spans of time
  # (see UNLISTED_RECOMMENDATION_TTL), and the catalogue has to keep expiring as quickly as it does
  # for the dialog to pick up a model that was pulled in the meantime.
  def unlisted_recommendation_cache_key(config)
    "#{cache_key(config)}/unlisted-embedding-recommendation"
  end
end
