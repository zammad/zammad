# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TextModulePolicy
  class Scope < ApplicationPolicy::Scope

    # change
    # create
    # all
    def resolve(context: :all)
      if user.permissions?('admin.text_module') && context == :all
        scope.all
      elsif user.permissions?('ticket.agent')
        agent_text_modules(context)
      else
        scope.none
      end
    end

    private

    def agent_text_modules(context)
      access = case context
               when :all
                 %i[change create]
               else
                 context
               end

      scope.available_in_groups user.group_ids_access(access)
    end
  end
end
