# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/command.rb'

module Tasks
  module Zammad
    module Package
      # Package migrations must not be executed in the same process that also executed
      #   Package.install or Package.link, as the codebase is in an inconsistent state.
      # This is enforced by Tasks:Zammad::Command which prevents command chaining.
      class Precompile < Tasks::Zammad::Command

        def self.description
          'Execute all package related precompilations.'
        end

        def self.setup_javascript_environment
          return if !::Package.app_frontend_files?

          if ::Package.app_package_installation?
            exec_command('zammad run pnpm install --production=false')
            exec_command('zammad run pnpm run generate-setting-types')
            exec_command('zammad run pnpm run generate-graphql-api')
          else
            exec_command('pnpm install --production=false')
            exec_command('pnpm run generate-setting-types')
            exec_command('pnpm run generate-graphql-api')
          end
        end

        def self.assets_precompile
          if ::Package.app_package_installation?
            exec_command('zammad run rake assets:precompile')
          else
            exec_command('rake assets:precompile')
          end
        end

        def self.task_handler
          setup_javascript_environment
          assets_precompile

          puts 'done.'
        end
      end
    end
  end
end
