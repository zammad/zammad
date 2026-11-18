# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Exchange::Connection < Sequencer::Unit::Common::Provider::Fallback

  uses :ews_config
  provides :ews_connection

  private

  def ews_connection
    require 'viewpoint' # Only load this gem when it is really used.

    # Viewpoint sends a blank password or token as it is, only nil counts as not given.
    Viewpoint::EWSClient.new({
                               endpoint: config[:endpoint],
                               type:     config[:auth_type],
                               token:    config[:access_token].presence,
                               user:     config[:user],
                               password: config[:password].presence
                             }, additional_opts)
  end

  def config
    @config ||= begin
      config = ews_config
      if !ews_config
        config = ::Import::Exchange.config
        if config[:auth_type] == 'oauth'
          config = config.merge(Setting.get('exchange_oauth'))
        end
      end
      config
    end
  end

  def additional_opts
    @additional_opts ||= { http_opts: http_opts }
  end

  # HTTPClient verifies against its own bundled CA list and ignores the custom SSL certificates
  # Zammad applies to the default OpenSSL context, so their store has to be passed explicitly.
  def http_opts
    return { ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE } if config[:disable_ssl_verify].present?

    { cert_store: Certificate::ApplySSLCertificates.ensure_fresh_ssl_context }
  end
end
