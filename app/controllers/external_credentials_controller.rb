# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class ExternalCredentialsController < ApplicationController
  before_action :authentication_check

  def index
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_index_render(ExternalCredential, params)
  end

  def show
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_show_render(ExternalCredential, params)
  end

  def create
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    # try access
    begin
      attributes = ExternalCredential.app_verify(params)
      model_create_render(ExternalCredential, { name: params[:provider].downcase, credentials: attributes })
      return
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def update
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    # try access
    begin
      attributes = ExternalCredential.app_verify(params)
      model_update_render(ExternalCredential, { name: params[:provider].downcase, credentials: attributes })
      return
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def destroy
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_destory_render(ExternalCredential, params)
  end

  def link_account
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    provider = params[:provider].downcase

    attributes = ExternalCredential.request_account_to_link(provider, callback_url(provider))

    session[:request_token] = attributes[:request_token]

    redirect_to attributes[:authorize_url]
  end

  def callback
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    provider = params[:provider].downcase

    channel = ExternalCredential.link_account(provider, session[:request_token], params)

    session[:request_token] = nil

    render json: channel
  end

  private

  def callback_url(provider)
    "#{Setting.get('http_type')}://#{Setting.get('fqdn')}#{Rails.configuration.api_path}/external_credentials/#{provider}/callback"
  end

end
