# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/command.rb'

module Tasks
  module Zammad
    module Package
      class PostInstall < Tasks::Zammad::Command
        def self.description
          'Runs all steps to finalize package installation.'
        end

        def self.task_handler
          if ::Package.app_package_installation?
            exec_command('zammad run rake zammad:package:migrate')
            exec_command('zammad run rake zammad:package:precompile')
          else
            exec_command('rake zammad:package:migrate')
            exec_command('rake zammad:package:precompile')
          end
        end
      end
    end
  end
end
