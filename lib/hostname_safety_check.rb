# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module HostnameSafetyCheck
  # The AWS instance metadata service answers over IPv6 at fd00:ec2::254 - a unique local address,
  # which counts as private rather than link-local, so allowing private addresses would admit it.
  METADATA_ENDPOINTS = [IPAddr.new('fd00:ec2::/64')].freeze

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
  # @return [String] the resolved IP address of the hostname
  # @raise [StandardError] if hostname is not safe or cannot be resolved
  def self.validate!(hostname, allow_private: false, allow_loopback: false, allow_link_local: false)
    resolved = IPSocket.getaddress(hostname)
    # An IPv4 address in IPv6 notation (::ffff:169.254.169.254, ::169.254.169.254) is judged as the
    # IPv4 address it stands for.
    ip       = IPAddr.new(resolved).native

    if METADATA_ENDPOINTS.any? { |network| network.include?(ip) }
      raise MetadataIpError.new(hostname, ip)
    end

    if !allow_private && ip.private?
      raise PrivateIpError.new(hostname, ip)
    end

    if !allow_loopback && ip.loopback?
      raise LoopbackIpError.new(hostname, ip)
    end

    if !allow_link_local && ip.link_local?
      raise LinkLocalIpError.new(hostname, ip)
    end

    resolved
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

  class MetadataIpError < SafetyError
    def self.message
      'The hostname is a cloud metadata service' # rubocop:disable Zammad/DetectTranslatableString
    end
  end
end
