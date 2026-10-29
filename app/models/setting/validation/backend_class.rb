# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Accepts only the values the code reading the setting expects, so a stored value can't point a
#   backend at any other loaded class.
class Setting::Validation::BackendClass < Setting::Validation::Base
  def run
    # A migration may save another attribute of a setting (e.g. its name) that still holds a value
    #   from before this validation was added.
    return result_success if !record.will_save_change_to_state_current?

    check_value
  end

  # Used by the migration adding this validation to check the stored values.
  def check_value
    return result_failed(__('The value of this setting has an invalid format.')) if !rule.valid_format?

    invalid = rule.backend_names.find { |name| !rule.backend?(name) }
    return result_success if invalid.nil?

    result_failed(format(__("'%s' is not a valid backend for this setting."), invalid))
  end

  private

  def rule
    @rule ||= Rule.for(record, value)
  end

  class Rule
    # Each of these settings registers one particular backend; another one of the same kind
    #   would silently replace it (e.g. the trusted filter or the trigger backend).
    REGISTRY_AREAS = %w[
      Dashboard::Stats
      Postmaster::PreFilter
      Postmaster::PostFilter
      Transaction::Backend::Sync
      Transaction::Backend::Async
    ].freeze

    attr_reader :record, :value

    # 'import_backends' is the only setting of its area naming classes, so it is keyed by name.
    def self.for(record, value)
      rule = if record.name == 'import_backends'
               ImportBackends
             elsif record.area == 'Security::Authentication'
               Authentication
             elsif REGISTRY_AREAS.include?(record.area)
               Registration
             else
               Selection
             end

      rule.new(record, value)
    end

    def initialize(record, value)
      @record = record
      @value  = value
    end

    def valid_format?
      value.is_a?(String)
    end

    def backend_names
      [value]
    end
  end

  # One of the setting's own select options.
  class Selection < Rule
    def backend?(name)
      options = record.options.dig(:form, 0, :options)

      options.is_a?(Hash) && options.key?(name)
    end
  end

  # The backend the setting was created with.
  class Registration < Rule
    def backend?(name)
      record.new_record? || name == initial_name
    end

    private

    def initial_name
      record.state_initial[:value]
    end
  end

  # A blank value switches the backend off (Auth::Backend drops it).
  class Authentication < Registration
    def valid_format?
      return true if value.blank?

      # Auth::Backend sorts all configurations by priority before it loads any of them.
      value.is_a?(Hash) && value[:adapter].is_a?(String) && (!value.key?(:priority) || value[:priority].is_a?(Integer))
    end

    def backend_names
      return [] if value.blank?

      [value[:adapter]]
    end

    private

    def initial_name
      record.state_initial[:value].try(:dig, :adapter)
    end
  end

  class ImportBackends < Rule
    def valid_format?
      value.is_a?(Array) && value.all?(String)
    end

    def backend_names
      value
    end

    def backend?(name)
      ImportJob.backend_valid?(name)
    end
  end
end
