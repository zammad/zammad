require 'yaml'

module IceCube
  module NullI18n
    def self.t(key, options = {})
      base = key.to_s.split('.').reduce(config) { |hash, current_key| hash[current_key] }

      base = base[options[:count] == 1 ? "one" : "other"] if options[:count]

      if base.is_a?(Hash)
        return base.each_with_object({}) do |(key, value), hash|
          hash[key.is_a?(String) ? key.to_sym : key] = value
        end
      end

      options.reduce(base) { |result, (find, replace)| result.gsub("%{#{find}}", "#{replace}") }
    end

    def self.l(date_or_time, options = {})
      return date_or_time.strftime(options[:format]) if options[:format]
      date_or_time.strftime(t('ice_cube.date.formats.default'))
    end

    def self.config
      @config ||= YAML.load(File.read(File.join(File.dirname(__FILE__), '..', '..', 'config', 'locales', 'en.yml')))['en']
    end
  end
end
