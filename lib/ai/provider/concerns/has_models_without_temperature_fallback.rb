# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider
  module Concerns::HasModelsWithoutTemperatureFallback
    extend ActiveSupport::Concern

    class_methods do
      def model_without_temperature?(model)
        self::DEFAULT_OPTIONS[:models_without_temperature].any? { |model_pattern| model.to_s.start_with?(model_pattern) }
      end
    end

    included do
      private

      def model_supports_temperature?
        # Honor the dynamically detected flag when it is stored (true or false).
        return config[:model_temperature_support] if config.key?(:model_temperature_support)

        # Fall back to the hardcoded list for backward compatibility.
        !self.class.model_without_temperature?(options[:model])
      end
    end
  end
end
