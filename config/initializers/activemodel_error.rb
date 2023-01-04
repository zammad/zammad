# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class ActiveModel::Error

  # Make it possible to retrieve errors that are translated with a Zammad locale.
  def localized_full_message(locale:, no_field_name: false)
    errors_hash = I18n.backend.translations[:en][:errors]
    orig_format = errors_hash[:format]
    errors_hash[:format] = Translation.translate(locale, 'This field %s', '%<message>s') if no_field_name
    I18n.with_zammad_locale(locale) do
      full_message
    end
  ensure
    errors_hash[:format] = orig_format
  end
end

module I18n
  def self.with_zammad_locale(locale)
    backend.zammad_locale = locale
    yield
  ensure
    backend.zammad_locale = nil
  end
end

class I18n::Backend::Simple

  attr_accessor :zammad_locale

  if !method_defined?(:orig_lookup)

    alias orig_lookup lookup

    # Allow I18n to load the default rails error messages from the YAML files,
    #   but translate them to the target locale before the error messages get generated
    #   including placeholder subsitition.
    def lookup(...)
      result = orig_lookup(...)
      if result.is_a?(String) && zammad_locale
        return Translation.translate(zammad_locale, result)
      end

      result
    end
  end
end
