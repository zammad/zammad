# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'tasks/zammad/package_command'

module Tasks
  module Zammad
    module Package
      class UpdateApi < Tasks::Zammad::PackageCommand
        def self.usage
          "#{super} all 7.0.x dry\n#{super} all 7.0.x prod"
        end

        def self.description
          'Update packages remotely via API to a certain version.'
        end

        ARGUMENT_COUNT = 3

        def self.task_handler
          package_name = ArgvHelper.argv[1]
          version_name = ArgvHelper.argv[2]
          prod_mode    = ArgvHelper.argv[3] == 'prod'

          validate_args!(version_name, ArgvHelper.argv[3])

          puts "Executing rake task in #{prod_mode ? 'prod mode' : 'dry mode'}..."

          show_post_install_hint = false
          ::Package.api_packages({ version_name: version_name }).each do |package_data|
            next if package_name != 'all' && package_data['name'] != package_name

            show_post_install_hint |= update_package(package_data, prod_mode)
          end

          return if !show_post_install_hint || !prod_mode

          puts "Please run package migrations now via 'zammad:package:post_install'."
        end

        def self.update_package(package_data, prod_mode)
          existing = ::Package.find_by(name: package_data['name'])
          return false if existing.blank?
          return false if Gem::Version.new(existing.version) >= Gem::Version.new(package_data['version'])

          puts "Updating #{package_data['name']} from version #{existing.version} to #{package_data['version']}..."
          ::Package.install(string: package_data.to_json) if prod_mode
          puts 'done.'
          true
        end
      end
    end
  end
end
