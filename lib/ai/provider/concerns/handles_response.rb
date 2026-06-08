# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider
  module Concerns::HandlesResponse
    extend ActiveSupport::Concern

    ERROR_MESSAGES = {
      400 => __('Invalid request - please check your input'),
      401 => __('Invalid API key - please check your configuration'),
      402 => __('Payment required - please top up your account'),
      403 => __('Forbidden - you do not have permission to access this resource'),
      404 => __('Not found - resource not found'),
      429 => __('Rate limit exceeded - please wait a moment'),
      500 => __('API server error - please try again'),
      502 => __('API server unavailable - please try again later'),
      503 => __('API server unavailable - please try again later'),
      529 => __('Service overloaded - please try again later'),
    }.freeze

    class_methods do
      def error_message_for_code(code)
        ERROR_MESSAGES[code] || __('An unknown error occurred')
      end

      def validate_response!(response)
        code = response.code.to_i
        return response.data if (200..399).cover?(code)

        message = error_message_for_code(code)
        raise AI::Provider::ResponseError, message
      end
    end

    included do
      delegate :validate_response!, :error_message_for_code, to: :class
    end
  end
end
