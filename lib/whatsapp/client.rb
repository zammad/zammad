# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'whatsapp_sdk'

class Whatsapp::Client

  attr_reader :access_token, :client

  def initialize(access_token:)
    @access_token = access_token

    raise ArgumentError, __("The required parameter 'access_token' is missing.") if access_token.nil?

    @client = WhatsappSdk::Api::Client.new(access_token)
  end

  def log_request(response: nil)
    return if response.empty?

    Rails.logger.error "WhatsApp Client: remote response: #{response}"
  end

  def handle_error(response:)
    return if response.body.nil?

    error = response.body['error']
    return if error.nil?

    log_request(response: response.body.inspect)

    message = error['message']
    if (details = error.dig('error_data', 'details'))
      message = "#{message}: #{details}"
    end

    raise CloudAPIError.new(message, response)
  end

  class CloudAPIError < StandardError
    attr_reader :original_error

    def initialize(message, original_error)
      super(message)

      @original_error = original_error
    end

    def retryable?
      return true if !original_error

      # https://developers.facebook.com/docs/graph-api/guides/error-handling
      recoverable_errors = [
        130_472, # User's number is part of an experiment
        131_021, # Recipient cannot be sender
        131_026, # Message undeliverable
        131_047, # Re-engagement message
        131_051, # Unsupported message type
        131_052, # Media download error
        131_053, # Media upload error
      ]

      recoverable_errors.include?(original_error.error_info.code)
    end
  end

  protected

  def with_tmpfile(prefix:, &)
    Tempfile.create(prefix, &)
  end

end
