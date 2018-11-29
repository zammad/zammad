require 'openssl'
require 'rack'
require 'json'

module Clearbit
  class Webhook < Mash
    def self.clearbit_key
      Clearbit.key!
    end

    def self.valid?(request_signature, body, key = nil)
      return false unless request_signature && body

      # The global Clearbit.key can be overriden for multi-tenant apps using multiple Clearbit keys
      key = (key || clearbit_key).gsub(/\A(pk|sk)_/, '')

      signature = generate_signature(key, body)
      Rack::Utils.secure_compare(request_signature, signature)
    end

    def self.valid!(signature, body, key = nil)
      valid?(signature, body, key) ? true : raise(Errors::InvalidWebhookSignature.new)
    end

    def self.generate_signature(key, body)
      'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), key, body)
    end

    def initialize(env, key = nil)
      request = Rack::Request.new(env)

      request.body.rewind

      signature = request.env['HTTP_X_REQUEST_SIGNATURE']
      body      = request.body.read

      self.class.valid!(signature, body, key)

      merge!(JSON.parse(body))
    end
  end
end
