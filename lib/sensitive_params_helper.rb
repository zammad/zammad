# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class SensitiveParamsHelper
  SENSITIVE_MASK = '**********'.freeze

  # Path segment suffix to descend into every element of an array of hashes,
  # e.g. `options.pages[].access_token` for the Facebook page access tokens.
  ARRAY_WILDCARD = '[]'.freeze

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

    # deep_dup first: nested values which are already HashWithIndifferentAccess would not be
    # copied by with_indifferent_access, so the masking below would modify the given payload
    payload = payload.deep_dup.with_indifferent_access

    attributes.each do |attr|
      *path, key = attr.to_s.split('.')

      each_nested_hash(payload, path) do |hash|
        next if !hash.key?(key)

        # Unset values are not secrets - masking them would make an unset field look configured.
        # Deliberately not `blank?`: `false` and whitespace-only strings are values, not the absence of one.
        next if unset?(hash[key])

        hash[key] = SENSITIVE_MASK
      end
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
    params        = params&.deep_dup&.with_indifferent_access # deep_dup for the same reason as in #mask

    attributes.each do |attr|
      unmask_single_attribute(attr, params, original_data)
    end

    params
  end

  private

  # Covers nil and the empty String / Hash / Array, but not `false`.
  def unset?(value)
    value.nil? || (value.respond_to?(:empty?) && value.empty?)
  end

  def unmask_single_attribute(attr, params, original_data)
    *path, key = attr.to_s.split('.')

    each_nested_hash(params, path, original_data) do |hash, original|
      next if hash[key] != SENSITIVE_MASK

      # without a counterpart the value is cleared, never left as the mask
      hash[key] = original.is_a?(Hash) ? original[key] : nil
    end
  end

  # Yields every hash reachable through the given path, expanding ARRAY_WILDCARD segments
  # over the elements of an array. The counterpart payload is traversed in parallel and
  # yielded alongside, so unmasking can restore the original value of the matching
  # element - see #counterpart_element for how array elements are paired.
  def each_nested_hash(node, path, counterpart = nil, &)
    return if !node.is_a?(Hash)
    return yield(node, counterpart) if path.blank?

    segment, *rest = path

    if segment.end_with?(ARRAY_WILDCARD)
      key   = segment.delete_suffix(ARRAY_WILDCARD)
      array = node[key]
      return if !array.is_a?(Array)

      counterpart_array = counterpart.is_a?(Hash) ? counterpart[key] : nil

      array.each do |element|
        each_nested_hash(element, rest, counterpart_element(counterpart_array, element), &)
      end

      return
    end

    each_nested_hash(node[segment], rest, (counterpart[segment] if counterpart.is_a?(Hash)), &)
  end

  # Array elements are matched by their `id`, never by their position: the payload may list
  # them in a different order than the counterpart - e.g. the Facebook channel dialog can
  # post back pages which were re-ordered by a meanwhile re-linked account - and a value
  # must never be restored from an element belonging to a different identity.
  def counterpart_element(counterpart_array, element)
    return if !counterpart_array.is_a?(Array)
    return if !element.is_a?(Hash) || element['id'].blank?

    counterpart_array.find { |elem| elem.is_a?(Hash) && elem['id'].to_s == element['id'].to_s }
  end
end
