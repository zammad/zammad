# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class SettingsController < ApplicationController
  prepend_before_action { authentication_check(permission: 'admin.*') }

  # GET /settings
  def index
    list = []
    Setting.all.each do |setting|
      next if setting.preferences[:permission] && !current_user.permissions?(setting.preferences[:permission])

      list.push setting
    end
    render json: list, status: :ok
  end

  # GET /settings/1
  def show
    check_access('read')
    model_show_render(Setting, params)
  end

  # POST /settings
  def create
    raise Exceptions::NotAuthorized, 'Not authorized (feature not possible)'
  end

  # PUT /settings/1
  def update
    check_access('write')
    clean_params = keep_certain_attributes
    model_update_render(Setting, clean_params)
  end

  # PUT /settings/image/:id
  def update_image
    check_access('write')
    clean_params = keep_certain_attributes

    if !clean_params[:logo]
      render json: {
        result:  'invalid',
        message: 'Need logo param',
      }
      return
    end

    # validate image
    if !clean_params[:logo].match?(/^data:image/i)
      render json: {
        result:  'invalid',
        message: 'Invalid payload, need data:image in logo param',
      }
      return
    end

    # process image
    file = StaticAssets.data_url_attributes(clean_params[:logo])
    if !file[:content] || !file[:mime_type]
      render json: {
        result:  'invalid',
        message: 'Unable to process image upload.',
      }
      return
    end

    # store image 1:1
    StaticAssets.store_raw(file[:content], file[:mime_type])

    # store resized image 1:1
    setting = Setting.lookup(name: 'product_logo')
    if params[:logo_resize] && params[:logo_resize] =~ /^data:image/i

      # data:image/png;base64
      file = StaticAssets.data_url_attributes(params[:logo_resize])

      # store image 1:1
      setting.state = StaticAssets.store(file[:content], file[:mime_type])
      setting.save!
    end

    render json: {
      result:   'ok',
      settings: [setting],
    }
  end

  # DELETE /settings/1
  def destroy
    raise Exceptions::NotAuthorized, 'Not authorized (feature not possible)'
  end

  private

  def keep_certain_attributes
    setting = Setting.find(params[:id])
    %i[name area state_initial frontend options].each do |key|
      params.delete(key)
    end
    if params[:preferences].present?
      %i[online_service_disable permission render].each do |key|
        params[:preferences].delete(key)
      end
      params[:preferences].merge!(setting.preferences)
    end
    params
  end

  def check_access(type)
    setting = Setting.lookup(id: params[:id])

    if setting.preferences[:permission] && !current_user.permissions?(setting.preferences[:permission])
      raise Exceptions::NotAuthorized, "Not authorized (required #{setting.preferences[:permission].inspect})"
    end

    if type == 'write'
      return true if !Setting.get('system_online_service')
      if setting.preferences && setting.preferences[:online_service_disable]
        raise Exceptions::NotAuthorized, 'Not authorized (service disabled)'
      end
    end
    true
  end
end
