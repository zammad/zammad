# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider
  module Concerns::HasModelsWithoutTemperatureFallback
    extend ActiveSupport::Concern

    included do
      private

      def model_supports_temperature?
        # Honor the dynamically detected flag when it is stored (true or false).
        return config[:model_temperature_support] if config.key?(:model_temperature_support)

        # Fall back to the hardcoded list for backward compatibility.
        current_model = options[:model]
        options[:models_without_temperature].none? { |model_pattern| current_model.start_with?(model_pattern) }
      end
    end
  end
end
