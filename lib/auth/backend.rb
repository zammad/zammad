# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Auth
  class Backend

    attr_reader :auth

    # @param name [String] class name stored as `adapter` of a 'Security::Authentication' setting
    # @return [Class, nil] the backend class, nil for anything but a subclass of Auth::Backend::Base
    def self.adapter_class(name)
      ApplicationLib.load_subclass(name, base: Auth::Backend::Base)
    end

    def initialize(auth)
      @auth = auth
    end

    def valid?
      instances.any? do |instance|
        next if !instance.valid?

        Rails.logger.info "Authentication against #{instance.class.name} for user #{auth.user.login} ok."

        true
      end
    end

    private

    def instances
      configs.filter_map do |config|
        adapter = self.class.adapter_class(config[:adapter])
        raise "'#{config[:adapter]}' is not an authentication backend" if !adapter

        adapter.new(config, auth)
      rescue => e
        Rails.logger.error "Failed to load Auth::Backend from Setting '#{config}'"
        Rails.logger.error e
        nil
      end
    end

    def configs
      Setting.where(area: 'Security::Authentication')
      .map { |setting| setting.state_current[:value] } # extract current Setting value as config
      .compact_blank
      .sort { |a, b| a.fetch(:priority, 999) <=> b.fetch(:priority, 999) } # sort by priority and fallback to append if not set
    end
  end
end
