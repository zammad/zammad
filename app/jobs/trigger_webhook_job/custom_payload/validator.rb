# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module TriggerWebhookJob::CustomPayload::Validator
  # This module validates replacement variables if there executed reference
  # object or method is allowed. This prevents the execution of arbitrary
  # code.

  private

  ALLOWED_SIMPLE_CLASSES = %w[
    Integer
    String
    Float
    FalseClass
    TrueClass
  ].freeze

  ALLOWED_RAILS_CLASSES = %w[
    ActiveSupport::TimeWithZone
    ActiveSupport::Duration
  ].freeze

  ALLOWED_CONTAINER_CLASSES = %w[
    Hash
    Array
  ].freeze

  ALLOWED_DEFAULT_CLASSES = ALLOWED_SIMPLE_CLASSES + ALLOWED_RAILS_CLASSES

  # This method executes the replacement variables and executes on any error,
  # e.g. no such method, no such object, missing method, etc. the error is
  # added to the mappping.
  def validate_methods!(methods, reference, display)
    return "\#{#{display} / missing method}" if methods.blank?

    methods.each_with_index do |method, index|
      display = "#{display}.#{method}"

      result = validate_method!(method, reference, display)
      return result if !result.nil?

      begin
        value = reference.send(method)
      rescue => e
        return "\#{#{display} / #{e.message}}"
      end

      return '' if value.nil?
      return validate_value!(value, display) if index == methods.size - 1

      reference = value
    end
  end

  # Final value must be one of the above described classes.
  def validate_value!(value, display)
    return validate_container_values(value) if value.class.to_s.in?(ALLOWED_CONTAINER_CLASSES)
    return "\#{#{display} / no such method}" if !value.class.to_s.in?(ALLOWED_DEFAULT_CLASSES)

    value
  end

  def validate_container_values(container)
    case container.class.to_s
    when 'Array'
      container.each_with_index do |value, index|
        container[index] = value.class.to_s.in?(ALLOWED_DEFAULT_CLASSES) ? value : 'no such item'
      end
    when 'Hash'
      container.each do |key, value|
        container[key] = value.class.to_s.in?(ALLOWED_DEFAULT_CLASSES) ? value : 'no such item'
      end
    end

    container
  end

  # Any top level object must be provided by the tracks hash (ticket, article,
  # notification by default, any further information is related to the webhook
  # content).
  def validate_object!(object, tracks)
    return "\#{no object provided}"         if object.blank?
    return "\#{#{object} / no such object}" if tracks.keys.exclude?(object.to_sym)

    nil
  end

  # Validate the next method to be called.
  def validate_method!(method, reference, display)
    return "\#{#{display} / missing method}" if method.blank?
    # Inspecting a symbol quotes invalid method names.
    return "\#{#{display} / no such method}" if method.to_sym.inspect.start_with?(%r{:"@?})
    return "\#{#{display} / no such method}" if !allowed_class_method?(method, reference)
    return "\#{#{display} / no such method}" if !reference.respond_to?(method.to_sym)

    nil
  end

  # This method verfies the class of a referenced object or the next method to
  # be called.
  def allowed_class_method?(method, reference)
    klass = reference.class.to_s

    # If the referenced object is one of the allowed simple classes no further
    # validation is required.
    return true if klass.in?(ALLOWED_DEFAULT_CLASSES)

    # The next method to be called must be explicit allowed within the
    # referenced track classes.
    tracks.select { |t| t.klass == klass }.each do |track|
      return true if track.functions.include?(method)
    end

    false
  end

  # This method verifies that the replaced custom payload is valid JSON.
  # This is done back and forth because the strictness of the JSON parser
  # is laxer than the JSON generator.
  def valid!(record)
    JSON.parse(record).to_json
  end
end
