# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class SettingsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  # GET /settings
  def index
    list        = Setting.all.filter { |elem| authorized?(elem, :show?) }
    masked_list = list.map { |object| mask_sensitive_values(object.as_json, object) }

    render json: masked_list, status: :ok
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
    permitted_params = params.permit(:id, state_current: {})
    raise ActionController::ParameterMissing, :state_current if !permitted_params[:state_current]&.key?(:value)

    permitted_params[:state_current] = permitted_params[:state_current].slice(:value)

    model_update_render(Setting, permitted_params)
  end

  # PUT /settings/image/:id
  def update_image
    setting = Setting.lookup(id: params[:id])
    raise Exceptions::UnprocessableContent, __('Only the product logo can be updated with an image.') if setting.name != 'product_logo'

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

  def model_item_render_attributes(object, attrs)
    return attrs if !object.vector_index_rebuild_started

    attrs.merge('vector_index_rebuild_started' => true)
  end

  # Setting hash value keys matching those partterns are sanitized.
  # Checks inclusion of the substring in the key.
  SENSITIVE_STATE_KEYS = %w[_key token secret bind_pw].freeze

  # Settings with matching names are sanitized as a whole
  # This is applied to non-boolean settings only!
  # Used for single-value settings that can't be sanitized based on value hash keys.
  # Checks inclusion of the substring in the name
  SENSITIVE_NAMES      = %w[_password _secret _key].freeze

  def sensitive_attributes(object_payload, object)
    return if object.options[:form].try(:one?) && object.options[:form].one? { |elem| elem[:tag] == 'boolean' }

    if SENSITIVE_NAMES.any? { |elem| object.name.include?(elem) }
      return ['state_current.value']
    end

    (object_payload.dig('state_current', 'value').try(:keys) || [])
      .select { |elem| elem.end_with?(*SENSITIVE_STATE_KEYS) }
      .map    { |elem| "state_current.value.#{elem}" }
  end
end
