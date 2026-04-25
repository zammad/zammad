# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Auth
  module Sso
    class TrustedIps
      def initialize(setting_value)
        @entries = setting_value.to_s.split(',').map(&:strip).compact_blank
      end

      def blank?
        @entries.empty?
      end

      def include?(ip)
        addr = IPAddr.new(ip)
        @entries.any? { |entry| IPAddr.new(entry).include?(addr) }
      rescue IPAddr::InvalidAddressError, IPAddr::AddressFamilyError
        false
      end

      def exclude?(ip)
        !include?(ip)
      end

      def first_invalid_entry
        @entries.find do |entry|
          begin
            IPAddr.new(entry) && false
          rescue
            true
          end
        end
      end
    end
  end
end
