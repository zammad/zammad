# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'pundit/matchers'

# Controller policies have default_permit! and permit! helpers.
# This does not work with Pundit bulk matchers because they rely on checking policy instance methods.
# Thus detecting routes pointing to the controller and using them as actions.

module Pundit
  module Matchers
    module Utils
      class PolicyInfo
        alias generic_actions actions

        def actions
          case policy
          when Controllers::ApplicationControllerPolicy
            controller_actions
          else
            generic_actions
          end
        end

        def controller_actions
          @controller_actions ||= Zammad::Application
            .routes
            .routes # this is not a typo
            .select { |elem| elem.defaults[:controller] == controller_class.controller_path }
            .map    { |elem| elem.defaults[:action].to_sym }
        end

        def controller_class
          @controller_class ||= policy
            .class
            .name
            .delete_prefix('Controllers::')
            .delete_suffix('Policy')
            .safe_constantize
        end
      end
    end
  end
end
