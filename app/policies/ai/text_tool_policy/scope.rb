# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::TextToolPolicy
  class Scope < ApplicationPolicy::Scope

    # change
    # create
    # all
    def resolve(context: :all)
      if user.permissions?('admin.ai_assistance_text_tools') && context == :all
        scope.all
      elsif user.permissions?('ticket.agent')
        agent_ai_text_tools(context)
      else
        scope.none
      end
    end

    private

    def agent_ai_text_tools(context)
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
