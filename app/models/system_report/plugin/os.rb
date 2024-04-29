# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SystemReport::Plugin::Os < SystemReport::Plugin
  OS_RELEASE_FILE = '/etc/os-release'.freeze

  DESCRIPTION = __('Operating system').freeze

  def fetch
    os_release.merge(platform: RUBY_PLATFORM).deep_symbolize_keys
  end

  private

  def os_release
    return {} if !File.exist?(OS_RELEASE_FILE)

    os_release = File.read(OS_RELEASE_FILE)
    begin
      os_release.split("\n").to_h do |line|
        key, value = line.split('=')
        key.downcase!
        value.delete!('"')

        [key, value]
      end
    rescue
      Rails.logger.error("Failed to parse #{OS_RELEASE_FILE}")
      {}
    end
  end
end
