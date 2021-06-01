# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ExternalCredentialsController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

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
    attributes = ExternalCredential.request_account_to_link(provider)
    session[:request_token] = attributes[:request_token]
    session[:channel_id] = params[:channel_id]
    redirect_to attributes[:authorize_url]
  end

  def callback
    provider = params[:provider].downcase
    channel = ExternalCredential.link_account(provider, session[:request_token], link_params)
    session[:request_token] = nil
    session[:channel_id] = nil
    redirect_to app_url(provider, channel.id)
  end

  private

  def link_params
    params.permit!.to_h.merge(channel_id: session[:channel_id])
  end

  def callback_url(provider)
    ExternalCredential.callback_url(provider)
  end

  def app_url(provider, channel_id)
    ExternalCredential.app_url(provider, channel_id)
  end
end
