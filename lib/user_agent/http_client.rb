# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class UserAgent::HttpClient
  HOST_PORT_REGEXP = %r{^(?:\[(.+?)\]|(.+?)):(\d+)$}
  NO_PROXY_DEFAULT = %w[localhost 127.0.0.1 ::1].freeze

  def initialize(uri, options)
    @uri     = uri
    @options = options
    @proxy   = fetch_proxy_configuration
  end

  def client
    proxy? ? build_proxy : Net::HTTP
  end

  def self.get_client(...)
    new(...).client
  end

  private

  attr_reader :uri, :options, :proxy

  def proxy?
    proxy && url_use_proxy?
  end

  def url_use_proxy?
    host = uri.hostname.downcase

    proxy_no.none? { url_use_proxy_single?(it, host) }
  end

  def url_use_proxy_single?(no_proxy_entry, host)
    return true if no_proxy_entry.start_with?('*.') && host.end_with?(no_proxy_entry[1..])

    host == no_proxy_entry
  end

  def build_proxy
    Net::HTTP::Proxy(proxy[:host], proxy[:port], proxy_username, proxy_password)
  end

  def fetch_proxy_configuration
    value = proxy_address

    return if value.blank?

    host, port = value
      .match(HOST_PORT_REGEXP)
      &.then do
        [it[1] || it[2], it[3]]
      end

    if host.blank? || port.blank?
      raise "Invalid proxy address: #{value} - expect e.g. proxy.example.com:3128"
    end

    { host:, port: }
  end

  def proxy_address
    options['proxy'] || Setting.get('proxy')
  end

  def proxy_username
    (options['proxy_username'] || Setting.get('proxy_username')).presence
  end

  def proxy_password
    (options['proxy_password'] || Setting.get('proxy_password')).presence
  end

  def proxy_no
    given_proxy_no = options['proxy_no'] || Setting.get('proxy_no') || ''

    NO_PROXY_DEFAULT + given_proxy_no.split(',').map { it.strip.downcase }
  end
end
