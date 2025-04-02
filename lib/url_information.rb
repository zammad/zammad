# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class UrlInformation < SimpleDelegator
  class UrlInformation::Error < StandardError; end

  DEFAULT_SCHEMA_PORTS = [['http', 80], ['https', 443]].freeze

  def initialize(url)
    uri = URI(url)
    raise UrlInformation::Error if %w[http https].exclude?(uri.scheme) || uri.host.blank?

    super(uri)
  rescue
    raise UrlInformation::Error
  end

  def fqdn
    @fqdn ||= begin
      if DEFAULT_SCHEMA_PORTS.include? [scheme, port]
        host
      else
        "#{host}:#{port}"
      end
    end
  end
end
