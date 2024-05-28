# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/command.rb'

module Tasks
  module Zammad
    module Package
      class BundleInstall < Tasks::Zammad::Command
        def self.description
          'Install package related gem files.'
        end

        def self.gem_install
          return if !::Package.gem_files?

          if ::Package.app_package_installation?
            exec_command('zammad config:set BUNDLE_DEPLOYMENT=0')
            exec_command("zammad run bundle config set --local deployment 'false'")
            exec_command('zammad run bundle install')
          else
            exec_command('bundle install')
          end
        end

        def self.task_handler
          gem_install

          puts 'done.'
        end
      end
    end
  end
end
