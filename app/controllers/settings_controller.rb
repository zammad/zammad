# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class SettingsController < ApplicationController
  before_action :authentication_check

  # GET /settings
  def index
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_index_render(Setting, params)
  end

  # GET /settings/1
  def show
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_show_render(Setting, params)
  end

  # POST /settings
  def create
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_create_render(Setting, params)
  end

  # PUT /settings/1
  def update
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    return if !check_access
    model_update_render(Setting, params)
  end

  # PUT /settings/image/:id
  def update_image
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    if !params[:logo]
      render json: {
        result: 'invalid',
        message: 'Need logo param',
      }
      return
    end

    # validate image
    if params[:logo] !~ /^data:image/i
      render json: {
        result: 'invalid',
        message: 'Invalid payload, need data:image in logo param',
      }
      return
    end

    # process image
    file = StaticAssets.data_url_attributes(params[:logo])
    if !file[:content] || !file[:mime_type]
      render json: {
        result: 'invalid',
        message: 'Unable to process image upload.',
      }
      return
    end

    # store image 1:1
    StaticAssets.store_raw(file[:content], file[:mime_type])

    # store resized image 1:1
    setting = Setting.find_by(name: 'product_logo')
    if params[:logo_resize] && params[:logo_resize] =~ /^data:image/i

      # data:image/png;base64
      file = StaticAssets.data_url_attributes( params[:logo_resize] )

      # store image 1:1
      setting.state = StaticAssets.store( file[:content], file[:mime_type] )
      setting.save
    end

    render json: {
      result: 'ok',
      settings: [setting],
    }
  end

  # DELETE /settings/1
  def destroy
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    return if !check_access
    model_destory_render(Setting, params)
  end

  private

  def check_access
    return true if !Setting.get('system_online_service')

    setting = Setting.find(params[:id])
    return true if setting.preferences && !setting.preferences[:online_service_disable]

    response_access_deny
    false
  end
end
