# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'tasks/zammad/package_command'

module Tasks
  module Zammad
    module Package
      class ListApi < Tasks::Zammad::PackageCommand
        def self.description
          'List packages remotely via API to a certain version.'
        end

        def self.task_handler
          abort "Please set a token to access addons on support.zammad.com via:\n\nroot> zammad rails r \"Setting.set('packages_token', 'xxx')\"\n\n" if ::Package.api_token.blank?

          puts 'Package'.ljust(50) + 'Version'.ljust(20) + 'Installed'.ljust(10) + 'Newest'.ljust(20)
          ::Package.api_packages({ branch_name: 'master' }).each do |package_data|
            existing_data = ::Package.find_by(name: package_data['name'])

            puts package_data['name'].ljust(50) + (existing_data ? existing_data['version'] : '').ljust(20) + (existing_data ? 'Yes' : 'No').ljust(10) + package_data['version'].ljust(20)
          end
        end
      end
    end
  end
end
