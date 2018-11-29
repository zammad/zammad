# frozen_string_literal: true
require 'jwt/json'
require 'jwt/verify'

# JWT::Decode module
module JWT
  extend JWT::Json

  # Decoding logic for JWT
  class Decode
    attr_reader :header, :payload, :signature

    def initialize(jwt, key, verify, options, &keyfinder)
      @jwt = jwt
      @key = key
      @verify = verify
      @options = options
      @keyfinder = keyfinder
    end

    def decode_segments
      header_segment, payload_segment, crypto_segment = raw_segments(@jwt, @verify)
      @header, @payload = decode_header_and_payload(header_segment, payload_segment)
      @signature = Decode.base64url_decode(crypto_segment.to_s) if @verify
      signing_input = [header_segment, payload_segment].join('.')
      [@header, @payload, @signature, signing_input]
    end

    def raw_segments(jwt, verify)
      segments = jwt.split('.')
      required_num_segments = verify ? [3] : [2, 3]
      raise(JWT::DecodeError, 'Not enough or too many segments') unless required_num_segments.include? segments.length
      segments
    end
    private :raw_segments

    def decode_header_and_payload(header_segment, payload_segment)
      header = JWT.decode_json(Decode.base64url_decode(header_segment))
      payload = JWT.decode_json(Decode.base64url_decode(payload_segment))
      [header, payload]
    end
    private :decode_header_and_payload

    def self.base64url_decode(str)
      str += '=' * (4 - str.length.modulo(4))
      Base64.decode64(str.tr('-_', '+/'))
    end

    def verify
      @options.each do |key, val|
        next unless key.to_s =~ /verify/

        Verify.send(key, payload, @options) if val
      end
    end
  end
end
