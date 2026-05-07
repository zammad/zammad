# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ExternalCredentialsController < ApplicationController
  include ExternalCredential::SensitiveAttributes

  prepend_before_action :authenticate_and_authorize!

  def index
    model_index_render(ExternalCredential, params)
  end

  def show
    model_show_render(ExternalCredential, params)
  end

  def create
    model_create_render(ExternalCredential, params)
  end

  def update
    model_update_render(ExternalCredential, params)
  end

  def destroy
    model_destroy_render(ExternalCredential, params)
  end

  def app_verify
    render json: { attributes: ExternalCredential.app_verify(params.permit!.to_h) }, status: :ok
  rescue => e
    logger.error e
    render json: { error: e.message }, status: :ok
  end

  def link_account
    provider = params[:provider].downcase
    attributes = ExternalCredential.request_account_to_link(provider, params)
    session[:request_token] = attributes[:request_token]
    session[:code_verifier] = attributes[:code_verifier]
    session[:channel_id] = params[:channel_id]
    session[:shared_mailbox] = params[:shared_mailbox]
    session[:notification] = [true, 'true'].include?(params[:notification])
    redirect_to attributes[:authorize_url], allow_other_host: true
  end

  def callback
    provider = params[:provider].downcase

    if session[:notification] && provider == 'microsoft_graph'
      return handle_notification_callback
    end

    channel = ExternalCredential.link_account(provider, session[:request_token], link_params)
    return redirect_to(channel), allow_other_host: true if channel.instance_of?(String)

    redirect_to app_url(provider, channel.id), allow_other_host: true
  ensure
    session[:request_token]  = nil
    session[:code_verifier]  = nil
    session[:channel_id]     = nil
    session[:shared_mailbox] = nil
    session[:notification]   = nil
  end

  private

  def handle_notification_callback
    request_token  = session[:request_token]
    shared_mailbox = session[:shared_mailbox]

    raise Exceptions::UnprocessableEntity, __('Invalid OAuth state parameter.') if params[:state] != request_token

    external_credential = ExternalCredential.find_by(name: 'microsoft_graph')
    raise Exceptions::UnprocessableEntity, __('No Microsoft Graph app configured!') if !external_credential
    raise Exceptions::UnprocessableEntity, __("The required parameter 'code' is missing.") if params[:code].blank?

    auth_data          = fetch_graph_auth_data(external_credential)
    preferred_username = extract_preferred_username(auth_data[:id_token])

    Service::System::SetEmailNotificationConfiguration.execute(
      adapter:              'microsoft_graph_outbound',
      new_configuration:    { user: preferred_username, shared_mailbox: shared_mailbox.presence },
      microsoft_graph_auth: auth_data,
    )

    redirect_to channels_email_url, allow_other_host: true
  end

  def fetch_graph_auth_data(external_credential)
    response = ExternalCredential::MicrosoftGraph.authorize_tokens(external_credential.credentials, params[:code])
    %w[refresh_token access_token expires_in scope token_type id_token].each do |key|
      raise Exceptions::UnprocessableEntity, "No #{key} for authorization request found!" if response[key.to_sym].blank?
    end

    response.merge(
      provider:      'microsoft_graph',
      type:          'XOAUTH2',
      client_id:     external_credential.credentials[:client_id],
      client_secret: external_credential.credentials[:client_secret],
      client_tenant: external_credential.credentials[:client_tenant],
    )
  end

  def extract_preferred_username(id_token)
    user_data = ExternalCredential::MicrosoftGraph.user_info(id_token)
    raise Exceptions::UnprocessableEntity, __("The user's 'preferred_username' could not be extracted from 'id_token'.") if user_data[:preferred_username].blank?

    user_data[:preferred_username]
  end

  def channels_email_url
    "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#channels/email"
  end

  def link_params
    params.permit!.to_h.merge(channel_id: session[:channel_id], shared_mailbox: session[:shared_mailbox], code_verifier: session[:code_verifier])
  end

  def callback_url(provider)
    ExternalCredential.callback_url(provider)
  end

  def app_url(provider, channel_id)
    ExternalCredential.app_url(provider, channel_id)
  end
end
