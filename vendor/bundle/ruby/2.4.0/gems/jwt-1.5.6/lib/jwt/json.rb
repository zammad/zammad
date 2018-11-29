# frozen_string_literal: true
require 'json'

module JWT
  # JSON fallback implementation or ruby 1.8.x
  module Json
    def decode_json(encoded)
      JSON.parse(encoded)
    rescue JSON::ParserError
      raise JWT::DecodeError, 'Invalid segment encoding'
    end

    def encode_json(raw)
      JSON.generate(raw)
    end
  end
end
