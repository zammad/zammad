# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class TranslationsController < ApplicationController
  before_filter :authentication_check, except: [:load]

  # GET /translations/lang/:locale
  def load
    render json: Translation.list( params[:locale] )
  end

  # GET /translations/admin/lang/:locale
  def admin
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    render json: Translation.list( params[:locale], true )
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
