# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The addresses the MCP server answers under: Zammad's configured ones, as the WebSocket servers accept them, and the
# loopback hosts. The transport specification asks for a foreign Origin to be refused, against DNS rebinding.
class Service::MCPServer::Addresses
  LOOPBACK_HOSTS = %w[127.0.0.1 ::1 localhost].freeze

  def self.hosts
    [Setting.get('fqdn'), Setting.get('alternative_fqdn')].compact_blank.map(&:downcase)
  end

  def self.origins
    Zammad::WebSocketOrigins.configured.map(&:downcase)
  end

  # @param host [String, nil] the Host header
  # @param origin [String, nil] the Origin header
  def self.allowed?(host:, origin:)
    host_allowed?(host) && origin_allowed?(origin, host)
  end

  # A request without a Host header, as HTTP/1.0 allows, cannot have been rebound.
  def self.host_allowed?(host)
    return true if host.nil?

    host = host.downcase
    allowed = hosts + LOOPBACK_HOSTS

    allowed.include?(host) || allowed.include?(hostname(host))
  end
  private_class_method :host_allowed?

  # Clients that are no browser send no Origin header.
  def self.origin_allowed?(origin, host)
    return true if origin.nil?

    origin = origin.downcase

    origins.include?(origin) || same_origin?(origin, host)
  end
  private_class_method :origin_allowed?

  def self.same_origin?(origin, host)
    return false if host.nil?

    default_port = origin.start_with?('https://') ? ':443' : ':80'
    authority    = origin.delete_prefix('https://').delete_prefix('http://')

    authority.delete_suffix(default_port) == host.downcase.delete_suffix(default_port)
  end
  private_class_method :same_origin?

  def self.hostname(host)
    return host[%r{\A\[([^\]]+)\]}, 1] if host.start_with?('[')

    host.split(':').first
  end
  private_class_method :hostname
end
