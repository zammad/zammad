# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'tasks/zammad/command'

class Tasks::Zammad::PackageCommand < Tasks::Zammad::Command
  def self.package_token
    ENV['PACKAGES_TOKEN'] || Setting.get('packages_token')
  end

  def self.validate_args!(version_name, mode)
    abort "Error: Invalid parameter version name '#{version_name}'!" if version_name.blank? || version_name !~ %r{^(\d+)\.(\d+)\.x\.?$}
    abort "Error: Invalid parameter execution mode '#{mode}'!" if %w[dry prod].exclude?(mode)
    abort "Please set a token to access addons on support.zammad.com via:\n\nroot> zammad rails r \"Setting.set('packages_token', 'xxx')\"\n\n" if ::Package.api_token.blank?
  end

  def self.request_zip_file(params)
    require 'zip'

    response = UserAgent.get('https://support.zammad.com/api/v1/addon_releases/download/organization', params, { bearer_token: package_token })
    abort 'Error: Download of organization package files failed!' if !response.code.starts_with?('2')

    zip_file = Tempfile.new
    zip_file.binmode
    zip_file.write(response.body)
    zip_file.rewind
    zip_file
  end
end
