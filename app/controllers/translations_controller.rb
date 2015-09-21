# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class TranslationsController < ApplicationController
  before_action :authentication_check, except: [:load]

  # GET /translations/lang/:locale
  def load
    render json: Translation.list( params[:locale] )
  end

  # PUT /translations/push
  def push
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    start = Time.zone.now
    Translation.push(params[:locale])
    if start > Time.zone.now - 5.seconds
      sleep 4
    end
    render json: { message: 'ok' }, status: :ok
  end

  # POST /translations/sync/:locale
  def sync
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    Translation.load(params[:locale])
    render json: { message: 'ok' }, status: :ok
  end

  # POST /translations/reset
  def reset
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    Translation.reset(params[:locale])
    render json: { message: 'ok' }, status: :ok
  end

  # GET /translations/admin/lang/:locale
  def admin
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    render json: Translation.list( params[:locale], true )
  end

  # GET /translations
  def index
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_index_render(Translation, params)
  end

  # GET /translations/1
  def show
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_show_render(Translation, params)
  end

  # POST /translations
  def create
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_create_render(Translation, params)
  end

  # PUT /translations/1
  def update
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_update_render(Translation, params)
  end

  # DELETE /translations/1
  def destroy
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_destory_render(Translation, params)
  end
end
