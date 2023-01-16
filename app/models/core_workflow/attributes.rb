# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'digest/md5'

class CoreWorkflow::Attributes
  attr_accessor :user, :payload, :assets

  def initialize(result_object:)
    @result_object = result_object
    @user          = result_object.user
    @payload       = result_object.payload
    @assets        = result_object.assets
  end

  def payload_class
    @payload['class_name'].constantize
  end

  def selected_only

    # params loading and preparing is very expensive so cache it
    checksum = Digest::MD5.hexdigest(Marshal.dump(@payload['params']))
    return @selected_only[checksum] if @selected_only.present? && @selected_only[checksum]

    @selected_only = {}
    @selected_only[checksum] = begin
      clean_params = payload_class.association_name_to_id_convert(@payload['params'])
      clean_params = payload_class.param_cleanup(clean_params, true, false, false)
      payload_class.new(clean_params)
    end
  end

  def selectable_field?(key)
    return if key == 'id'
    return if !@payload['params'].key?(key)

    # some objects have no attributes like "CoreWorkflow"-object as well.
    # attributes only exists in the frontend so we skip this check
    return true if object_elements.blank?

    object_elements_hash.key?(key)
  end

  def overwrite_selected(result)
    selected_attributes = selected_only.attributes
    selected_attributes.each_key do |key|
      next if !selectable_field?(key)

      # special behaviour for owner id
      if key == 'owner_id' && selected_attributes[key].nil?
        selected_attributes[key] = 1
      end

      result[key.to_sym] = selected_attributes[key]
    end
    result
  end

  def exists?
    return if @payload['params']['id'].blank?

    @exists ||= payload_class.exists?(id: @payload['params']['id'])
  end

  def overwritten

    # params loading and preparing is very expensive so cache it
    checksum = Digest::MD5.hexdigest(Marshal.dump(@payload['params']))
    return @overwritten[checksum] if @overwritten.present? && @overwritten[checksum]

    @overwritten = {}
    @overwritten[checksum] = begin
      result = saved_only(dump: true)
      overwrite_selected(result)
    end
  end

  def selected
    if exists?
      overwritten
    else
      selected_only
    end
  end

  def saved_only(dump: false)
    return if !exists?

    # dont use lookup here because the cache will not
    # know about new attributes and make crashes
    @saved_only ||= payload_class.find_by(id: @payload['params']['id'])

    return @saved_only if !dump

    # we use marshal here because clone still uses references and dup can't
    # detect changes for the rails object
    Marshal.load(Marshal.dump(@saved_only))
  end

  def saved
    @saved ||= saved_only || payload_class.new
  end

  def object_elements
    @object_elements ||= ObjectManager::Object.new(@payload['class_name']).attributes(@user, saved_only, data_only: false).each_with_object([]) do |element, result|
      result << element.data.merge(screens: element.screens)
    end
  end

  def object_elements_hash
    @object_elements_hash ||= object_elements.index_by { |x| x[:name] }
  end

  def screen_value(attribute, type)
    screen_value = attribute[:screens].dig(@payload['screen'], type)
    return screen_value if !screen_value.nil?

    attribute[type.to_sym]
  end

  def request_id_default
    payload['request_id']
  end

  # dont cache this else the result object will work with references and cache bugs occur
  def visibility_default
    object_elements.each_with_object({}) do |attribute, result|
      result[ attribute[:name] ] = screen_value(attribute, 'shown') == false ? 'remove' : 'show'
    end
  end

  def attribute_mandatory?(attribute)
    return screen_value(attribute, 'required').present? if !screen_value(attribute, 'required').nil?
    return screen_value(attribute, 'null').blank? if !screen_value(attribute, 'null').nil?

    false
  end

  # dont cache this else the result object will work with references and cache bugs occur
  def mandatory_default
    object_elements.each_with_object({}) do |attribute, result|
      result[ attribute[:name] ] = attribute_mandatory?(attribute)
    end
  end

  # dont cache this else the result object will work with references and cache bugs occur
  def auto_select_default
    object_elements.each_with_object({}) do |attribute, result|
      next if !attribute[:only_shown_if_selectable]

      result[ attribute[:name] ] = true
    end
  end

  # dont cache this else the result object will work with references and cache bugs occur
  def readonly_default
    object_elements.each_with_object({}) do |attribute, result|
      result[ attribute[:name] ] = false
    end
  end

  def select_default
    @result_object.result[:select] || {}
  end

  def fill_in_default
    @result_object.result[:fill_in] || {}
  end

  def eval_default
    []
  end

  def matched_workflows_default
    @result_object.result[:matched_workflows] || []
  end

  def rerun_count_default
    @result_object.result[:rerun_count] || 0
  end

  def options_array(options)
    result = []

    options.each do |option|
      result << option['value']
      if option['children'].present?
        result += options_array(option['children'])
      end
    end

    result
  end

  def options_hash(options)
    options.keys
  end

  def options_relation(attribute)
    key = "#{attribute[:relation]}_#{attribute[:name]}"
    @options_relation ||= {}
    @options_relation[key] ||= "CoreWorkflow::Attributes::#{attribute[:relation]}".constantize.new(attributes: self, attribute: attribute)
    @options_relation[key].values
  end

  def attribute_filter?(attribute)
    screen_value(attribute, 'filter').present?
  end

  def attribute_options_array?(attribute)
    attribute[:options].present? && attribute[:options].instance_of?(Array)
  end

  def attribute_options_hash?(attribute)
    attribute[:options].present? && attribute[:options].instance_of?(Hash)
  end

  def attribute_options_relation?(attribute)
    attribute[:tag] == 'select' && attribute[:relation].present?
  end

  def values(attribute)
    values = nil
    if attribute_filter?(attribute)
      values = screen_value(attribute, 'filter')
    elsif attribute_options_array?(attribute)
      values = options_array(attribute[:options])
    elsif attribute_options_hash?(attribute)
      values = options_hash(attribute[:options])
    elsif attribute_options_relation?(attribute)
      values = options_relation(attribute)
    end
    values
  end

  def values_empty(attribute, values)
    return values if values == ['']

    saved_value = saved_attribute_value(attribute)
    if saved_value.present?
      values |= Array(saved_value).map(&:to_s)
    end

    if screen_value(attribute, 'nulloption') && values.exclude?('')
      values.unshift('')
    end

    values
  end

  def restrict_values_default
    result = {}
    object_elements.each do |attribute|
      values = values(attribute)
      next if values.blank?

      values = values_empty(attribute, values)
      result[ attribute[:name] ] = values.map(&:to_s)
    end
    result
  end

  def all_options_default
    object_elements.each_with_object({}) do |attribute, result|
      next if !attribute_options_array?(attribute) && !attribute_options_hash?(attribute)

      result[ attribute[:name] ] = attribute[:options]
    end
  end

  def saved_attribute_value(attribute)

    # special case for owner_id
    return if saved_only&.class == Ticket && attribute[:name] == 'owner_id'

    saved_only&.try(attribute[:name])
  end
end
