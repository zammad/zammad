# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Setting::Validation::KbSelfHostedVideoServers < Setting::Validation::Base
  def run
    if !value.is_a?(Array)
      return result_failed(__('Self-hosted video servers list must be an array.'))
    end

    if !value.all? { valid_server?(it) }
      return result_failed(__('One or more self-hosted video servers are invalid. Please check the host names.'))
    end

    result_success
  end

  private

  def valid_server?(server)
    host = server['host']

    return false if host.blank?

    parsed = begin
      URI.parse("https://#{host}")
    rescue URI::InvalidURIError
      nil
    end

    parsed.present? && host_with_optional_port(parsed) == host
  end

  def host_with_optional_port(uri)
    if uri.port == uri.default_port
      return uri.host
    end

    "#{uri.host}:#{uri.port}"
  end
end
