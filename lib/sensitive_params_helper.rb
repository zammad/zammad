# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class SensitiveParamsHelper
  SENSITIVE_MASK = '**********'.freeze

  attr_reader :attributes

  def initialize(attributes)
    @attributes = Array(attributes)
  end

  # Masks sensitive values in the given object payload by replacing them with SENSITIVE_MASK.
  #
  # @example
  #   payload = { preferences: { bind_pw: 'secret123' } }
  #   mask_sensitive_values(payload, ldap_source)
  #   # => { preferences: { bind_pw: '**********' } }
  def mask(payload)
    return payload if attributes.blank?

    payload = payload.with_indifferent_access

    attributes.each do |attr|
      *path, key = attr.to_s.split('.')

      hash = path.blank? ? payload : payload.dig(*path)

      next if !hash&.key?(key)

      payload.deep_merge! build_masked_sensitive_hash(attr)
    end

    payload
  end

  # Unmasks sensitive parameters by restoring original values from the object
  # when the parameter contains SENSITIVE_MASK.
  #
  # @example
  #   params = { preferences: { bind_pw: '**********' } }
  #   unmask_sensitive_params(params, ldap_source)
  #   # => { preferences: { bind_pw: 'original_secret' } }
  def unmask(params, object)
    return params if attributes.blank?

    if params.respond_to?(:permit!)
      params = params.permit!.to_h
    end

    original_data = object&.as_json&.with_indifferent_access
    params        = params&.with_indifferent_access

    attributes.each do |attr|
      unmask_single_attribute(attr, params, original_data)
    end

    params
  end

  private

  def build_masked_sensitive_hash(attr)
    *path, key = attr.to_s.split('.')

    output = { key => SENSITIVE_MASK }

    # builds nested hash from path
    Array(path).reverse.reduce(output) { |memo, elem| { elem => memo } }
  end

  def unmask_single_attribute(attr, params, original_data)
    # binding.pry
    *path, key = attr.to_s.split('.')

    hash = path.blank? ? params : params.dig(*path)
    # binding.pry

    return if !hash || hash[key] != SENSITIVE_MASK

    # binding.pry

    hash[key] = original_data.dig(*path, key)
  end
end
