# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module FormUpdater::Concerns::ProvidesInitialValues
  extend ActiveSupport::Concern

  def resolve
    if meta[:initial] && respond_to?(:initial_values)
      initial_values.each do |name, value|
        next if data[name].present?

        # Provide value as part of data payload too, so core workflow can work with it.
        data[name] = value

        result[name] ||= {}
        result[name][:initialValue] = value
      end
    end

    super
  end
end
