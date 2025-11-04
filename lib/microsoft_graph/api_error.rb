# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class MicrosoftGraph
  class ApiError < StandardError
    attr_reader :error, :retry_after

    def initialize(error_hash, retry_after: nil)
      @error       = error_hash.with_indifferent_access
      @retry_after = retry_after

      super()
    end

    def error_code
      error[:code] || 'no error code present'
    end

    def error_message
      error[:message] || 'An unknown error occurred.' # rubocop:disable Zammad/DetectTranslatableString
    end

    def request_id
      error.dig(:innerError, :'request-id')
    end

    def message
      output = "#{error_message} (#{error_code})"

      if request_id
        output += "\nMicrosoft Graph API Request ID: #{request_id}"
      end

      output
    end

    def inspect
      "#<#{self.class.name}: #{message.dump}>"
    end
  end
end
