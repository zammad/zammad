# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class TranslationsController < ApplicationController
  before_filter :authentication_check, :except => [:load]

  # GET /translations/:lang
  def load
    translations = Translation.where( :locale => params[:locale] )

    list = []
    translations.each { |item|
      data = [
        item.id,
        item.source,
        item.target,
      ]
      list.push data
    }

    timestamp_map_default = 'yyyy-mm-dd HH:MM'
    timestamp_map = {
      :de => 'dd.mm.yyyy HH:MM',
    }
    timestamp = timestamp_map[ params[:locale].to_sym ] || timestamp_map_default

    render :json => {
      :list            => list,
      :timestampFormat => timestamp,
    }
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
    model_destory_render(Translation, params)
  end
end
