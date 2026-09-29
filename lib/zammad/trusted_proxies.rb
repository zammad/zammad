# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Zammad
  class TrustedProxies

    class << self

      # Resolve any hostnames in the RAILS_TRUSTED_PROXIES environment variable and return the final list
      #   as IPAddr objects, so that address ranges like "10.0.0.0/8" match in Rails' RemoteIp middleware.
      def fetch
        resolve_hostnames(parse_env) || [IPAddr.new('127.0.0.1'), IPAddr.new('::1')]
      end

      private

      def resolve_hostnames(list)
        return if !list.is_a?(Array)

        list
          .map { addresses_for(it) }
          .flatten
          .compact
      end

      def addresses_for(entry)
        IPAddr.new(entry)
      rescue IPAddr::InvalidAddressError
        # Not an IP address or range, so treat the entry as a hostname.
        Resolv
          .getaddresses(entry)
          .filter_map { |address| parse_resolved_address(entry, address) }
          .tap do |resolved|
            # Rails.logger may not be available here, so we use warn directly.
            warn "Error: ignoring trusted proxy '#{entry}' because it cannot be resolved." if resolved.empty?
          end
      end

      # Resolv::Hosts returns the raw first column of /etc/hosts, which IPAddr may reject.
      def parse_resolved_address(entry, address)
        IPAddr.new(address)
      rescue IPAddr::InvalidAddressError
        warn "Error: ignoring address '#{address}' of trusted proxy '#{entry}' because it is not a valid IP address."
        nil
      end

      def parse_env
        return if ENV['RAILS_TRUSTED_PROXIES'].blank?

        if ENV['RAILS_TRUSTED_PROXIES'].strip.start_with?('[')
          # Backwards compatibility for Docker environments setting the variable to a
          #   Ruby literal like "['127.0.0.1', '::1']".
          YAML.safe_load(ENV['RAILS_TRUSTED_PROXIES'])
        else
          # The regular way: variable contains a list if IP addresses/masks: "127.0.0.1,::1"
          ENV['RAILS_TRUSTED_PROXIES'].split(',').compact_blank
        end
      end
    end
  end
end
