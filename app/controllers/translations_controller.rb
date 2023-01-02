# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TranslationsController < ApplicationController
  prepend_before_action -> { authentication_check && authorize! }, except: [:lang]

  # GET /translations/lang/:locale
  def lang
    render json: Translation.lang(params[:locale])
  end

  # POST /translations/reset
  def reset
    Translation.reset(params[:locale])
    render json: { message: 'ok' }, status: :ok
  end

  # GET /translations/admin/lang/:locale
  def admin
    render json: Translation.lang(params[:locale], true)
  end

  # GET /translations
  def index
    model_index_render(Translation, params)
  end

  # GET /translations/1
  def show
    model_show_render(Translation, params)
  end

  # POST /translations
  def create
    model_create_render(Translation, params)
  end

  # PUT /translations/1
  def update
    model_update_render(Translation, params)
  end

  # DELETE /translations/1
  def destroy
    model_destroy_render(Translation, params)
  end
end
