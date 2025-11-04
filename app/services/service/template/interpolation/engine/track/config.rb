# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Template::Interpolation::Engine::Track::Config < Service::Template::Interpolation::Engine::Track
  class << self
    def root?
      true
    end

    def klass
      'Struct::Config'
    end

    def functions
      %w[
        fqdn
        http_type
        ticket_hook
      ].freeze
    end

    def replacements
      {
        config: functions,
      }
    end

    def generate(tracks, _data)
      settings = {}
      functions.each do |setting|
        settings[setting] = Setting.get(setting)
      end

      Struct.new('Config', *settings.keys) if !defined?(Struct::Config)

      tracks[:config] = Struct::Config.new(*settings.values)
    end
  end
end
