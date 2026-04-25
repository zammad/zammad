# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module HostnameSafetyCheck
  # Checks if hostname resolves to a safe IP address
  # This is to prevent Server-Side Request Forgery (SSRF) attacks
  # Domains can resolve to any IP. And IP itself can be in various obfuscated forms to mask an offensive address.
  #
  # Please note that private IP addresses may be safe or not based on context.
  # If address is put in by the same person who manages the network, it's probably safe.
  # But if address is put in by an external user, it's probably not!
  # So in different scenarios you may want to allow or disallow private IP addresses.
  #
  # @param hostname [String] The domain or IP address fo to check
  # @param allow_private [Boolean] Whether to allow private IP addresses (e.g. 192.168.x.x)
  # @param allow_loopback [Boolean] Whether to allow loopback IP addresses (e.g. 127.0.0.1)
  # @param allow_link_local [Boolean] Whether to allow link-local IP addresses (e.g. 169.254.x.x)
  #
  # @return [Boolean] true if hostname is safe, otherwise raises an error
  # @raise [StandardError] if hostname is not safe or cannot be resolved
  def self.validate!(hostname, allow_private: false, allow_loopback: false, allow_link_local: false)
    resolved = IPSocket.getaddress(hostname)
    ip       = IPAddr.new(resolved)

    if !allow_private && ip.private?
      raise PrivateIpError.new(hostname, ip)
    end

    if !allow_loopback && ip.loopback?
      raise LoopbackIpError.new(hostname, ip)
    end

    if !allow_link_local && ip.link_local?
      raise LinkLocalIpError.new(hostname, ip)
    end

    true
  rescue => e
    raise e if e.is_a?(SafetyError)

    raise SafetyError.new(hostname) # rubocop:disable Style/RaiseArgs
  end

  class SafetyError < StandardError
    def initialize(hostname, ip = nil)
      address = ip ? "#{hostname} (#{ip})" : hostname

      super("#{self.class.message}: #{address}")
    end

    def self.message
      'Could not ensure safety of the hostname' # rubocop:disable Zammad/DetectTranslatableString
    end
  end

  class PrivateIpError < SafetyError
    def self.message
      'The hostname is a private IP' # rubocop:disable Zammad/DetectTranslatableString
    end
  end

  class LoopbackIpError < SafetyError
    def self.message
      'The hostname is a loopback IP' # rubocop:disable Zammad/DetectTranslatableString
    end
  end

  class LinkLocalIpError < SafetyError
    def self.message
      'The hostname is a link-local IP' # rubocop:disable Zammad/DetectTranslatableString
    end
  end
end
