# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::ProviderConnectionsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!
  before_action :test_provider_accessible!, only: %i[create update]

  def index
    model_index_render(AI::ProviderConnection, params)
  end

  def show
    model_show_render(AI::ProviderConnection, params)
  end

  def create
    # A created connection can serve semantic search the moment it exists - flagged in the request,
    # or automatically as the first connection - and the index is then rebuilt for whatever it
    # embeds with. The index comes out correct either way; the challenge is only so that the same
    # rebuild #update and #set_default ask about is not silently bought through a third door.
    return if serves_embeddings_after_create? && embedding_rebuild_unconfirmed?(
      after: submitted_embedding_configuration,
    )

    model_create_render(AI::ProviderConnection, params)
  end

  def update
    connection = AI::ProviderConnection.find(params[:id])

    # Only what the connection serving semantic search embeds with matters: what any other one is
    # configured with was never indexed, so editing it invalidates nothing.
    #
    # Whether it will serve it after the save, not whether it does now - `default_embedding` is a
    # column like any other, so an update can hand semantic search over without going through
    # #set_default, and would otherwise rebuild the whole index unasked.
    return if serves_embeddings_after_update?(connection) && embedding_rebuild_unconfirmed?(
      after: submitted_embedding_configuration(connection),
    )

    model_update_render(AI::ProviderConnection, params)
  end

  def search
    model_search_render(AI::ProviderConnection, params)
  end

  def destroy
    model_destroy_render(AI::ProviderConnection, params)
  end

  def set_default
    # Validated against the known purposes before it becomes an attribute name: an unknown value
    # would otherwise reach #update! as `default_<anything>` and raise an internal error.
    purpose = params.require(:default)
    raise Exceptions::UnprocessableContent, __('Unknown default purpose.') if AI::ProviderConnection::DEFAULT_PURPOSES.exclude?(purpose)

    connection = AI::ProviderConnection.find(params[:id])
    return render_provider_error(__('This provider does not support embeddings.')) if purpose == 'embedding' && !connection.embedding_capable

    enabled       = params.key?(:enabled) ? params[:enabled] : true
    serves_search = purpose == 'embedding' && ActiveModel::Type::Boolean.new.cast(enabled)

    # Serving embeddings requires a named model. Rather than reject this one-click action for a
    # connection that predates the explicit field, it gets the provider's recommendation - the same
    # rule the connection seeding follows. A provider with nothing to name still fails, with the
    # validation message telling the admin to configure a model first.
    #
    # Before the confirmation, which compares the model this action is about to run on - the seeded
    # one included.
    connection.seed_embedding_default if serves_search

    # Handing semantic search to another connection embeds the knowledge base with whatever that one
    # runs on, so what it would run on is compared against what the index holds. Clearing it leaves
    # nothing to embed with, which is no rebuild and needs no confirmation.
    return if serves_search && embedding_rebuild_unconfirmed?(
      after: Service::AI::VectorDB::Embedding::Configuration.of(connection),
    )

    connection.update!("default_#{purpose}" => enabled)
    model_show_render(AI::ProviderConnection, params)
  end

  # The models the endpoint offers, for the dialog's model dropdown, along with the defaults its
  # empty options stand for. Answers with { models:, default_model:, recommended_embedding_model:,
  # recommended_embedding_metadata:, error: }. A provider with no model list at all
  # (Azure AI, Zammad AI) answers 422 - its dialog never asks. A present `error` is a listing that
  # failed, which the wizard's credential step names as the reason it does not let the admin any
  # further.
  def models
    connection = AI::ProviderConnection.find(params[:id]) if params.key?(:id)

    result = Service::AI::ProviderConnection::ListModels.execute(
      provider:        params[:provider].to_s.presence || connection&.provider,
      incoming_config: submitted_config,
      existing_config: connection&.config || {},
      # Attributes the listing request's HTTP log to the connection; nil while it is being created.
      related_object:  connection,
    )

    render json: result
  # A failed listing is not a failed request: the dialog has to tell "the provider refused the
  # listing" from "the endpoint rejected what you typed", and puts the reason in front of the
  # credentials it was rejected for. Hence 200 with an error instead of a 4xx. URI::Error stands
  # for a malformed URL, which raises out of UserAgent before its own rescue.
  rescue AI::Provider::RequestError, AI::Provider::ResponseError, URI::Error => e
    render json: { models: [], error: e.message }
  end

  # The dimensions and the input limit of one embedding model, for the fields the dialog fills
  # instead of sending the admin off to research them. Only asked for where the model listing
  # could not size the model itself - a value no source knows comes back as null, which the dialog
  # answers with a field the admin has to fill.
  def embedding_metadata
    connection = AI::ProviderConnection.find(params[:id]) if params.key?(:id)

    result = Service::AI::ProviderConnection::ResolveEmbeddingMetadata.execute(
      provider:        params[:provider].to_s.presence || connection&.provider,
      model:           params[:model].to_s,
      incoming_config: submitted_config,
      existing_config: connection&.config || {},
      # Attributes the metadata request's HTTP log to the connection; nil while it is being created.
      related_object:  connection,
    )

    render json: result
  end

  private

  # The submitted config, or nil when none was submitted, so the stored one is listed against
  # unchanged. Mask sentinels in it are resolved by the service, which knows the stored config -
  # exactly like the connection test does.
  def submitted_config
    return nil if !params.key?(:config)

    # Anything but a hash is a malformed request rather than a config to list against, and would
    # otherwise raise on permit!.
    raise ActionController::ParameterMissing, :config if !params[:config].is_a?(ActionController::Parameters)

    params[:config].permit!.to_h
  end

  # Validates the provider endpoint is reachable before persisting, and records whether the
  # model supports the temperature parameter.
  def test_provider_accessible!
    provider_key, existing = provider_and_existing_connection
    return if provider_key.blank?

    existing_config = existing&.config || {}

    # nil (config omitted, stored config is validated) is distinct from {} (explicitly cleared).
    incoming_config = params[:config]&.permit!.to_h if params.key?(:config)

    support = Service::AI::ProviderConnection::TestConnection.execute(
      provider:        provider_key,
      incoming_config: incoming_config,
      existing_config: existing_config,
      # Attributes the test request's HTTP log to the connection; nil while it is being created.
      related_object:  existing,
    )

    # The detected flag has to reach the config that gets stored on both paths: an update that
    # changes only the provider submits none, and would otherwise keep the previous provider's
    # value, which AI::Provider#model_supports_temperature? then applies to every request.
    params[:config] = (incoming_config || existing_config).merge('model_temperature_support' => support)
  # Only errors caused by the admin's input render as a provider error in the dialog: provider
  # errors from the connection test, unknown provider keys, and malformed URLs (URI::Error
  # raises out of UserAgent before its own rescue). Anything else is a Zammad-side bug and
  # bubbles to the standard error handling (logged 500) instead of masquerading as a 422.
  rescue AI::Provider::RequestError, AI::Provider::ResponseError, Exceptions::UnprocessableContent, URI::Error => e
    render_provider_error(e.message)
  end

  # A blank provider key signals "skip the check": a rename that changes neither the provider
  # nor the config must not re-test the endpoint.
  # @return [Array(String, AI::ProviderConnection)] the provider key to test (blank = skip) and the
  #   connection being edited, nil while one is created.
  def provider_and_existing_connection
    # The action, not params[:id]: the legacy frontend submits its client-side id ('c-0') when
    # creating, which would look like an update of a record that does not exist (= skip). Only an
    # update has a stored record, so anything else errs towards testing rather than skipping.
    return [params[:provider].to_s, nil] if action_name != 'update'

    existing = AI::ProviderConnection.find_by(id: params[:id])
    return [nil, nil] if existing.nil?

    provider_key = params[:provider].presence || existing.provider
    # Key presence, not blankness: an explicitly emptied config ({}) is a change that has to be
    # tested, only an omitted one means the stored config still applies unchanged.
    return [nil, nil] if provider_key == existing.provider && !params.key?(:config)

    [provider_key, existing]
  end

  def render_provider_error(message)
    render json: { error: message }, status: :unprocessable_content
  end

  # Answers the challenge with the reply that carries it, and tells the action to stop there.
  #
  # The reply names the validator to skip, which is what the dialog sends back on Proceed - so a
  # client that does not know the convention gets a rejected request with a reason rather than an
  # index it never asked to have rebuilt.
  #
  # @return [Boolean] whether the request was answered and the action must not go on
  def embedding_rebuild_unconfirmed?(after:)
    return false if skip_validators.include?(Service::AI::ProviderConnection::Validator::EmbeddingRebuild::IDENTIFIER)

    Service::AI::ProviderConnection::Validator::EmbeddingRebuild.execute(after:)

    false
  rescue Service::AI::ProviderConnection::Validator::EmbeddingRebuild::Error => e
    render json: { error: e.message, error_human: e.message, skip_validator: e.skip_validator }, status: :unprocessable_content

    true
  end

  def skip_validators
    Array(params[:skip_validators]).map(&:to_s)
  end

  # Whether this connection is the one semantic search runs on once the submitted attributes are
  # stored - the flag it carries now, unless the save itself changes it.
  def serves_embeddings_after_update?(connection)
    return ActiveModel::Type::Boolean.new.cast(params[:default_embedding]) if params.key?(:default_embedding)

    connection.default_embedding?
  end

  # Whether the connection will serve semantic search the moment it exists: flagged by the request
  # itself, or automatically as the first connection
  # (AI::ProviderConnection#seed_initial_optional_defaults). The automatic flag only lands where the
  # provider can embed at all, but that needs no mirroring here - a configuration nothing embeds
  # with resolves to nil, which no validator warns about.
  def serves_embeddings_after_create?
    return true if ActiveModel::Type::Boolean.new.cast(params[:default_embedding])

    !AI::ProviderConnection.exists?
  end

  # What the submitted attributes amount to, as the save would store them: an omitted config leaves
  # the stored one in place, and an omitted provider the stored provider - on a create, where there
  # is nothing stored, they amount to nothing. The token is the only masked value and none of this
  # reads it, so the mask never looks like a change.
  def submitted_embedding_configuration(connection = nil)
    Service::AI::VectorDB::Embedding::Configuration.for_provider(
      provider: params[:provider].presence || connection&.provider,
      config:   params.key?(:config) ? params[:config].to_unsafe_h : connection&.config || {},
    )
  end

  # Lets model_update_render's unmask_sensitive_params restore the stored token when the
  # admin submits the mask sentinel instead of a new value.
  def sensitive_attributes(object_payload, _object)
    CanMaskConfigSecrets.sensitive_config_attributes(object_payload)
  end
end
