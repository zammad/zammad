# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Organization
  module Search
    extend ActiveSupport::Concern

    include CanSearch

    # methods defined here are going to extend the class, not the instance of it
    class_methods do

=begin

search organizations preferences

  result = Organization.search_preferences(user_model)

returns if user has permissions to search

  result = {
    prio: 1000,
    direct_search_index: true
  }

returns if user has no permissions to search

  result = false

=end

      def search_preferences(current_user)
        return false if !current_user.permissions?(['ticket.agent', 'ticket.customer', 'admin.organization'])

        {
          prio:                1500,
          direct_search_index: !customer_only?(current_user),
        }
      end

      def customer_only?(current_user)
        return true if current_user.permissions?('ticket.customer') && !current_user.permissions?(['admin.organization', 'ticket.agent'])

        false
      end

      def search_default_sort_by
        %w[active updated_at]
      end

      def search_default_order_by
        %w[desc desc]
      end

      def search_params_pre(params)
        return if !customer_only?(params[:current_user])

        params[:ids] = params[:current_user].all_organization_ids
      end
    end
  end
end
