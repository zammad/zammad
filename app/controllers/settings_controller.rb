# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SettingsController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

  # GET /settings
  def index
    list = []
    Setting.all.each do |setting|
      next if !authorized?(setting, :show?)

      list.push setting
    end
    render json: list, status: :ok
  end

  # GET /settings/1
  def show
    model_show_render(Setting, params)
  end

  # POST /settings
  def create
    raise Exceptions::Forbidden, 'Not authorized (feature not possible)'
  end

  # PUT /settings/1
  def update
    clean_params = keep_certain_attributes
    model_update_render(Setting, clean_params)
  end

  # PUT /settings/image/:id
  def update_image
    clean_params = keep_certain_attributes

    if !clean_params[:logo]
      render json: {
        result:  'invalid',
        message: 'Need logo param',
      }
      return
    end

    # validate image
    if !clean_params[:logo].match?(%r{^data:image}i)
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
    if params[:logo_resize] && params[:logo_resize] =~ %r{^data:image}i

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
    raise Exceptions::Forbidden, 'Not authorized (feature not possible)'
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
end
