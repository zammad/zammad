# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class User
  module Search
    extend ActiveSupport::Concern

    include CanSearch

    included do
      scope :search_sql_extension, lambda { |params|
        statement = all

        if params[:role_ids]
          statement = statement.joins(:roles).where('roles.id' => params[:role_ids])
        end

        if params[:group_ids]
          user_ids = []
          params[:group_ids].each do |group_id, access|
            user_ids |= User.group_access(group_id.to_i, access).pluck(:id)
          end
          statement = if user_ids.present?
                        statement.where(id: user_ids)
                      else
                        statement.none
                      end
        end

        # Fixes #3755 - User with user_id 1 is show in admin interface (which should not)
        statement.where('users.id != 1')
      }
    end

    # methods defined here are going to extend the class, not the instance of it
    class_methods do

=begin

search user preferences

  result = User.search_preferences(user_model)

returns if user has permissions to search

  result = {
    prio: 1000,
    direct_search_index: true
  }

returns if user has no permissions to search

  result = false

=end

      def search_preferences(current_user)
        return false if !current_user.permissions?(['ticket.agent', 'admin.user'])

        {
          prio:                2000,
          direct_search_index: true,
        }
      end

      def search_default_sort_by
        %w[active updated_at]
      end

      def search_default_order_by
        %w[desc desc]
      end

      def search_params_pre(params)
        return if params[:permissions].blank?

        params[:role_ids] ||= []
        params[:role_ids] |= Role.with_permissions(params[:permissions]).pluck(:id)
      end

      def search_query_extension(params)
        query_extension = {}
        if params[:role_ids].present?
          query_extension['bool'] ||= {}
          query_extension['bool']['must'] ||= []
          if !params[:role_ids].is_a?(Array)
            params[:role_ids] = [params[:role_ids]]
          end
          access_condition = {
            'query_string' => { 'default_field' => 'role_ids', 'query' => "\"#{params[:role_ids].join('" OR "')}\"" }
          }
          query_extension['bool']['must'].push access_condition
        end

        if params[:group_ids].present?
          user_ids = []
          params[:group_ids].each do |group_id, access|
            user_ids |= User.group_access(group_id.to_i, access).pluck(:id)
          end

          if user_ids.present?
            query_extension['bool'] ||= {}
            query_extension['bool']['must'] ||= []
            query_extension['bool']['must'].push({ 'terms' => { '_id' => user_ids } })
          else
            query_extension = {
              bool: {
                must: [
                  {
                    'query_string' => { 'query' => 'id:0' }
                  },
                ],
              }
            }
          end
        end

        query_extension
      end
    end
  end
end
