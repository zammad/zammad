# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# This file collects a few Rails extensions to make it possible to translate both
# errors built into Rails or other gems, and also our custom errors in the Zammad codebase.
#
# It works generally like this:
# - The zammad:translation_catalog generator has an extractor that will find error message strings
#   defined by Rails and other gems and put them into the catalog of translatable strings.
# - The I18n gem is extended to perform the actual translation lookups via the Zammad Translations API.
#

# Ensure the error message hash is loaded, as the code below relies on it.
I18n.eager_load!

module ActiveModel
  class Error

    # Make it possible to retrieve errors that are translated with a Zammad locale.
    #   no_field_name indicates that the default behaviour of Rails which includes the field name
    #   in the error message should be modified to say "This field ..." rather than "#{fieldname} ...".
    def localized_full_message(locale:, no_field_name: false)
      override_errors_format(locale, no_field_name) do
        ::I18n.with_zammad_locale(locale) do
          full_message
        end
      end
    end

    private

    def override_errors_format(locale, no_field_name)
      errors_hash = ::I18n.backend.translations[:en][:errors]
      orig_format = errors_hash[:format]
      errors_hash[:format] = ::Translation.translate(locale, 'This field %s', '%{message}') if no_field_name
      yield
    ensure
      errors_hash[:format] = orig_format
    end
  end

  class Errors

    if !method_defined?(:orig_add)

      alias orig_add add

      # This will add custom string errors to the I18n translation store.
      def add(attribute, type = :invalid, **)
        return orig_add(attribute, type, **) if !type.is_a?(String)

        # I18n uses namespacing to access the messages, so generate a safe symbol without the namespace separator '.'.
        type_sym = type.gsub(%r{\W}, '').to_sym
        ::I18n.backend.translations[:en][:errors][:messages][type_sym] = type
        orig_add(attribute, type_sym, **)
      end
    end
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
