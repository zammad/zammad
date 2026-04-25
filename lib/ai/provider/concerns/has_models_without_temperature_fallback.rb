# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider
  module Concerns::HasModelsWithoutTemperatureFallback
    extend ActiveSupport::Concern

    included do
      private

      def model_supports_temperature?
        # Use the dynamically detected flag if it has been set.
        return config[:model_temperature_support] if config[:model_temperature_support].present?

        # Fall back to the hardcoded list for backward compatibility.
        current_model = options[:model]
        options[:models_without_temperature].none? { |model_pattern| current_model.start_with?(model_pattern) }
      end
    end
  end
end
