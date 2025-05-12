# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider
  module Concerns::HandlesResponse
    extend ActiveSupport::Concern

    def error_message_for_code(code)
      case code
      when 400
        __('Invalid request - please check your input')
      when 401
        __('Invalid API key - please check your configuration')
      when 402
        __('Payment required - please top up your account')
      when 403
        __('Forbidden - you do not have permission to access this resource')
      when 404
        __('Not found - resource not found')
      when 429
        __('Rate limit exceeded - please wait a moment')
      when 500
        __('API server error - please try again')
      when 502, 503
        __('API server unavailable - please try again later')
      when 529
        __('Service overloaded - please try again later')
      else
        __('An unknown error occurred')
      end
    end

    included do
      def validate_response!(response)
        code = response.code.to_i
        return response.data if (200..399).cover?(code)

        message = error_message_for_code(code)
        raise AI::Provider::ResponseError, message
      end
    end
  end
end
