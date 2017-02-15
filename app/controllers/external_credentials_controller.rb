# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class ExternalCredentialsController < ApplicationController
  prepend_before_action { authentication_check(permission: ['admin.channel_twitter', 'admin.channel_facebook']) }

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
    attributes = ExternalCredential.app_verify(params)
    render json: { attributes: attributes }, status: :ok
    return
  rescue => e
    render json: { error: e.message }, status: :ok
  end

  def link_account
    provider = params[:provider].downcase
    attributes = ExternalCredential.request_account_to_link(provider)
    session[:request_token] = attributes[:request_token]
    redirect_to attributes[:authorize_url]
  end

  def callback
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
