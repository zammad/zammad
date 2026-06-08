# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::System::Import::ApplyConfigurationBase < Service::Base

  attr_reader :url, :endpoint, :secret, :username, :tls_verify

  def initialize(url:, secret: nil, username: nil, tls_verify: true)
    configured!

    @url = url
    @endpoint = build_endpoint
    @secret = secret
    @username = username
    @tls_verify = tls_verify
  end

  def execute
    reachable!
    accessible! if @secret.present?
  end

  private

  def build_endpoint
    raise NotImplementedError
  end

  def reachable!
    raise NotImplementedError
  end

  def accessible!
    raise NotImplementedError
  end

  def request(url, options = {})
    response = UserAgent.get(url, {}, options)
    raise TLSError, __('The server presented a certificate that could not be verified.') if response.error&.include?('OpenSSL::SSL::SSLError')

    response
  end

  def configured!
    raise Service::System::CheckSetup::SystemSetupError, __('This system has already been configured.') if Service::System::CheckSetup.done?
  end

  class UnreachableError < StandardError; end
  class InaccessibleError < StandardError; end
  class TLSError < StandardError; end
end
