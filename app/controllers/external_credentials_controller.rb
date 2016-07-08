# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class ExternalCredentialsController < ApplicationController
  before_action :authentication_check

  def index
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_index_render(ExternalCredential, params)
  end

  def show
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_show_render(ExternalCredential, params)
  end

  def create
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_create_render(ExternalCredential, params)
  end

  def update
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_update_render(ExternalCredential, params)
  end

  def destroy
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_destory_render(ExternalCredential, params)
  end

  def app_verify
    attributes = ExternalCredential.app_verify(params)
    render json: { attributes: attributes }, status: :ok
    return
  rescue => e
    render json: { error: e.message }, status: :ok
  end

  def link_account
    deny_if_not_role(Z_ROLENAME_ADMIN)
    provider = params[:provider].downcase
    attributes = ExternalCredential.request_account_to_link(provider)
    session[:request_token] = attributes[:request_token]
    redirect_to attributes[:authorize_url]
  end

  def callback
    deny_if_not_role(Z_ROLENAME_ADMIN)
    provider = params[:provider].downcase
    channel = ExternalCredential.link_account(provider, session[:request_token], params)
    session[:request_token] = nil
    redirect_to app_url(provider, channel.id)
  end

  private

  def callback_url(provider)
    ExternalCredential.callback_url(provider)
  end

  def app_url(provider, channel_id)
    ExternalCredential.app_url(provider, channel_id)
  end

end
