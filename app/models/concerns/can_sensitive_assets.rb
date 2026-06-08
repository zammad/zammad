# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module CanSensitiveAssets
  extend ActiveSupport::Concern

  # Override this in controllers where sanitization is needed.
  # Example: `[:preferences.bind_pw]` for LdapSource
  SENSITIVE_FIELDS = [].freeze

  def self_assets
    mask_sensitive_values(super, self)
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

  #
  # Returns the list of sensitive attributes that should be masked.
  # Override in controllers where custom sanitization is needed.
  #
  # @example
  #   sensitive_attributes(params, ldap_source)
  #   # => [:preferences.bind_pw]
  def sensitive_attributes(_input, _object)
    self.class.const_get(:SENSITIVE_FIELDS)
  end
end
