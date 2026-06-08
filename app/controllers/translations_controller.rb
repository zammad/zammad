# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class TranslationsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!, except: [:lang]

  def lang
    render json: Translation.lang(params[:locale])
  end

  # GET /translations/customized
  def index_customized
    render json: Translation.customized.details, status: :ok
  end

  # GET /translations/search/:locale
  def search
    render json: Service::Translation::Search.execute(locale: params[:locale], query: params[:query]), status: :ok
  end

  # POST /translations/upsert
  def upsert
    render json: Service::Translation::Upsert.execute(locale: params[:locale], source: params[:source], target: params[:target]), status: :ok
  end

  # POST /translations/reset
  def reset
    Translation.reset(params[:locale])
    render json: { message: 'ok' }, status: :ok
  end

  # PUT /translations/reset/:id
  def reset_item
    translation = Translation.find(params[:id])

    render json: translation.reset, status: :ok
  end

  # GET /translations
  def index
    model_index_render(Translation, params)
  end

  # GET /translations/1
  def show
    model_show_render(Translation, params)
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
