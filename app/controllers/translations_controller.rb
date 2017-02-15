# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class TranslationsController < ApplicationController
  prepend_before_action :authentication_check, except: [:lang]

  # GET /translations/lang/:locale
  def lang
    render json: Translation.lang(params[:locale])
  end

  # PUT /translations/push
  def push
    permission_check('admin.translation')
    start = Time.zone.now
    Translation.push(params[:locale])
    if start > Time.zone.now - 4.seconds
      sleep 3
    end
    render json: { message: 'ok' }, status: :ok
  end

  # POST /translations/sync/:locale
  def sync
    permission_check('admin.translation')
    Translation.load(params[:locale])
    render json: { message: 'ok' }, status: :ok
  end

  # POST /translations/reset
  def reset
    permission_check('admin.translation')
    Translation.reset(params[:locale])
    render json: { message: 'ok' }, status: :ok
  end

  # GET /translations/admin/lang/:locale
  def admin
    permission_check('admin.translation')
    render json: Translation.lang(params[:locale], true)
  end

  # GET /translations
  def index
    permission_check('admin.translation')
    model_index_render(Translation, params)
  end

  # GET /translations/1
  def show
    permission_check('admin.translation')
    model_show_render(Translation, params)
  end

  # POST /translations
  def create
    permission_check('admin.translation')
    model_create_render(Translation, params)
  end

  # PUT /translations/1
  def update
    permission_check('admin.translation')
    model_update_render(Translation, params)
  end

  # DELETE /translations/1
  def destroy
    permission_check('admin.translation')
    model_destroy_render(Translation, params)
  end
end
