# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class ExternalCredentialsController < ApplicationController
  prepend_before_action :permission_check

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
    redirect_to attributes[:authorize_url]
  end

  def callback
    provider = params[:provider].downcase
    channel = ExternalCredential.link_account(provider, session[:request_token], params.permit!.to_h)
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

  def permission_check
    if params[:id].present? && ExternalCredential.exists?(params[:id])
      external_credential = ExternalCredential.find(params[:id])
      raise 'No such ExternalCredential!' if !external_credential

      authentication_check(permission: ["admin.channel_#{external_credential.name}"])
      return
    end

    if params[:name].present? || params[:provider].present?
      if params[:name].present?
        name = params[:name].downcase
      elsif params[:provider].present?
        name = params[:provider].downcase
      else
        raise 'Missing name/provider!'
      end
      authentication_check(permission: ["admin.channel_#{name}"])
      return
    end

    authentication_check(permission: ['admin'])
  end

end
