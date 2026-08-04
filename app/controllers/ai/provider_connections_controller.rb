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
    model_create_render(AI::ProviderConnection, params)
  end

  def update
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

    enabled = params.key?(:enabled) ? params[:enabled] : true
    connection.update!("default_#{purpose}" => enabled)
    model_show_render(AI::ProviderConnection, params)
  end

  private

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

  # Lets model_update_render's unmask_sensitive_params restore the stored token when the
  # admin submits the mask sentinel instead of a new value.
  def sensitive_attributes(object_payload, _object)
    CanMaskConfigSecrets.sensitive_config_attributes(object_payload)
  end
end
