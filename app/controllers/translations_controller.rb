# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class TranslationsController < ApplicationController
  before_action :authentication_check, except: [:lang]

  # GET /translations/lang/:locale
  def lang
    render json: Translation.lang(params[:locale])
  end

  # PUT /translations/push
  def push
    deny_if_not_role(Z_ROLENAME_ADMIN)
    start = Time.zone.now
    Translation.push(params[:locale])
    if start > Time.zone.now - 5.seconds
      sleep 4
    end
    render json: { message: 'ok' }, status: :ok
  end

  # POST /translations/sync/:locale
  def sync
    deny_if_not_role(Z_ROLENAME_ADMIN)
    Translation.load(params[:locale])
    render json: { message: 'ok' }, status: :ok
  end

  # POST /translations/reset
  def reset
    deny_if_not_role(Z_ROLENAME_ADMIN)
    Translation.reset(params[:locale])
    render json: { message: 'ok' }, status: :ok
  end

  # GET /translations/admin/lang/:locale
  def admin
    deny_if_not_role(Z_ROLENAME_ADMIN)
    render json: Translation.lang(params[:locale], true)
  end

  # GET /translations
  def index
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_index_render(Translation, params)
  end

  # GET /translations/1
  def show
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_show_render(Translation, params)
  end

  # POST /translations
  def create
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_create_render(Translation, params)
  end

  # PUT /translations/1
  def update
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_update_render(Translation, params)
  end

  # DELETE /translations/1
  def destroy
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_destory_render(Translation, params)
  end
end
