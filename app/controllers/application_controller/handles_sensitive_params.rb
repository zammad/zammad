# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module ApplicationController::HandlesSensitiveParams
  extend ActiveSupport::Concern

  SENSITIVE_MASK = '**********'.freeze

  # Override this in controllers where sanitization is needed.
  # Example: `[:preferences.bind_pw]` for LdapSource
  SENSITIVE_FIELDS = [].freeze

  # Returns the list of sensitive attributes that should be masked.
  # Override in controllers where custom sanitization is needed.
  #
  # @example
  #   sensitive_attributes(params, ldap_source)
  #   # => [:preferences.bind_pw]
  def sensitive_attributes(_input, _object)
    self.class.const_get(:SENSITIVE_FIELDS)
  end

  # Masks sensitive values in the given object payload by replacing them with SENSITIVE_MASK.
  #
  # @example
  #   payload = { preferences: { bind_pw: 'secret123' } }
  #   mask_sensitive_values(payload, ldap_source)
  #   # => { preferences: { bind_pw: '**********' } }
  def mask_sensitive_values(object_payload, object)
    SensitiveParamsHelper
      .new(sensitive_attributes(object_payload, object))
      .mask(object_payload)
  end

  # Unmasks sensitive parameters by restoring original values from the object
  # when the parameter contains SENSITIVE_MASK.
  #
  # @example
  #   params = { preferences: { bind_pw: '**********' } }
  #   unmask_sensitive_params(params, ldap_source)
  #   # => { preferences: { bind_pw: 'original_secret' } }
  def unmask_sensitive_params(params, object)
    SensitiveParamsHelper
      .new(sensitive_attributes(params, object))
      .unmask(params, object)
  end
end
