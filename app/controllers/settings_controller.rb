# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SettingsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

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
    raise Exceptions::Forbidden, __('Not authorized (feature not possible)')
  end

  # PUT /settings/1
  def update
    model_update_render(Setting, keep_certain_attributes)
  end

  # PUT /settings/image/:id
  def update_image
    logo_content = %i[logo logo_resize].each_with_object({}) do |key, memo|
      data = params[key]

      next if !data&.match? %r{^data:image}i

      file = ImageHelper.data_url_attributes(data)

      memo[key] = file[:content] if file
    end

    logo_timestamp = Service::SystemAssets::ProductLogo.store(logo_content[:logo], logo_content[:logo_resize])

    if !logo_timestamp
      render json: {
        result:  'invalid',
        message: __('The uploaded image could not be processed. Need data:image in logo or logo_resize param.'),
      }
      return
    end

    setting = Setting.lookup(name: 'product_logo')
    setting.state = logo_timestamp
    setting.save!

    render json: {
      result:   'ok',
      settings: [setting],
    }
  end

  # DELETE /settings/1
  def destroy
    raise Exceptions::Forbidden, __('Not authorized (feature not possible)')
  end

  # POST /settings/reset/1
  def reset
    setting = Setting.find(params[:id])
    Setting.reset(setting.name)

    setting.reload

    if response_expand?
      render json: setting.attributes_with_association_names, status: :ok
      return
    end

    if response_full?
      render json: setting.class.full(setting.id), status: :ok
      return
    end

    render json: setting.attributes_with_association_ids, status: :ok
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
