# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider
  module Concerns::HasConfigurableModel
    extend ActiveSupport::Concern

    included do
      def model_for(prompt_image:)
        return options[:model] if !prompt_image.is_a?(::Store)

        config[:ocr_model] || options[:model]
      end
    end
  end
end
