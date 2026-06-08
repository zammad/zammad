# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Zammad
  class TrustedProxies

    class << self

      # Resolve any hostnames in the RAILS_TRUSTED_PROXIES environment variable and return the final list.
      def fetch
        resolve_hostnames(parse_env) || ['127.0.0.1', '::1']
      end

      private

      def resolve_hostnames(list)
        return if !list.is_a?(Array)

        list.map { |entry| resolve(entry) }.flatten.compact
      end

      def resolve(entry)
        entry if IPAddr.new(entry)
      rescue IPAddr::InvalidAddressError
        Resolv.getaddresses(entry).tap do |resolved|
          # Rails.logger may not be available here, so we use warn directly.
          warn "Error: ignoring trusted proxy '#{entry}' because it cannot be resolved." if resolved.empty?
        end
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
