# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Ticket::Search
  extend ActiveSupport::Concern

  include CanSearch

  CUSTOMER_SEARCH_FIELDS         = %w[title number hook_number state.name customer.firstname customer.lastname organization.name].freeze
  CUSTOMER_SEARCH_SYNTAX_FIELDS  = (CUSTOMER_SEARCH_FIELDS + %w[id]).freeze
  CUSTOMER_SEARCH_ARTICLE_FIELDS = %w[article.subject article.body article.from article.to article.cc article.attachment._name article.attachment.content].freeze

  # Ticket attributes without customer access, see also TicketPolicy#customer_field_scope.
  CUSTOMER_HIDDEN_TICKET_ATTRIBUTES = %r{\A(tags|mention_user_ids|checklist|time_unit|accounted_time_type|ai_)}
  # Attributes of related objects with customer access, see also UserPolicy and OrganizationPolicy.
  CUSTOMER_CONDITION_ATTRIBUTES = %w[customer.firstname customer.lastname owner.firstname owner.lastname organization.name].freeze

  included do
    # Conditions on hidden attributes restrict the search to the agent access of the user.
    scope :search_sql_extension, lambda { |params|
      where(group_id: search_agent_group_ids(params)) if search_agent_access_only?(params)
    }

    scope :search_sql_query_extension, lambda { |params|
      query = params[:query]&.delete('*')
      return if query.blank?

      fields = %w[title number]
      fields << Ticket::Article.arel_table[:body]
      fields << Ticket::Article.arel_table[:from]
      fields << Ticket::Article.arel_table[:to]
      fields << Ticket::Article.arel_table[:subject]

      where_or_cis(fields, "%#{SqlHelper.quote_like(query)}%")
        .joins(search_sql_articles_join(params))
    }
  end

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

=begin

search tickets preferences

  result = Ticket.search_preferences(user_model)

returns if user has permissions to search

  result = {
    prio: 3000,
    direct_search_index: false
  }

returns if user has no permissions to search

  result = false

=end

    def search_preferences(current_user)
      return false if !current_user.permissions?(['ticket.agent', 'ticket.customer'])

      {
        prio:                3000,
        direct_search_index: false,
      }
    end

    def search_params_pre(params)
      params[:scope] ||= TicketPolicy::ReadScope
    end

    def search_agent_group_ids(params)
      return [] if !params[:current_user].permissions?('ticket.agent')

      params[:current_user].group_ids_access(params[:scope].const_get(:ACCESS_TYPE))
    end

    def search_customer_access?(params)
      params[:current_user].permissions?('ticket.customer') && !search_agent_access_only?(params)
    end

    def search_agent_access_only?(params)
      return false if !params[:current_user].permissions?('ticket.customer')

      search_condition_names(params[:condition]).any? { |name| !search_customer_condition?(name) }
    end

    def search_customer_condition?(name)
      table, attribute = name.include?('.') ? name.split('.', 2) : ['ticket', name]
      return CUSTOMER_CONDITION_ATTRIBUTES.include?(name) if table != 'ticket'

      !attribute.match?(CUSTOMER_HIDDEN_TICKET_ATTRIBUTES)
    end

    def search_condition_names(condition)
      condition = condition.to_unsafe_h if condition.respond_to?(:to_unsafe_h)
      return [] if condition.blank?

      search_selector_names(Selector::Base.migrate_selector(condition.deep_symbolize_keys))
    end

    def search_selector_names(selector)
      selector[:conditions].flat_map do |condition|
        condition.key?(:conditions) ? search_selector_names(condition) : [condition[:name].to_s]
      end
    end

    def search_sql_articles_join(params)
      tickets  = arel_table
      articles = Ticket::Article.arel_table

      visible   = articles[:internal].eq(false)
      group_ids = search_agent_group_ids(params)
      if group_ids.present?
        visible = visible.or(tickets[:group_id].in(group_ids))
      end

      tickets
        .join(articles, Arel::Nodes::OuterJoin)
        .on(articles[:ticket_id].eq(tickets[:id]).and(visible))
        .join_sources
    end

    def search_query_extension(params)
      query_or  = []
      group_ids = search_agent_group_ids(params)
      if group_ids.present?
        access_condition = {
          'query_string' => { 'default_field' => 'group_id', 'query' => "\"#{group_ids.join('" OR "')}\"" }
        }
        query_or.push(access_condition)
      end
      if search_customer_access?(params)
        organizations_query = params[:current_user].all_organizations.where(shared: true).map { |row| "organization_id:#{row.id}" }.join(' OR ')
        access_condition    = if organizations_query.present?
                                {
                                  'query_string' => { 'query' => "customer_id:#{params[:current_user].id} OR #{organizations_query}" }
                                }
                              else
                                {
                                  'query_string' => { 'default_field' => 'customer_id', 'query' => params[:current_user].id }
                                }
                              end
        query_or.push(access_condition)
      end

      if query_or.blank?
        return {
          bool: {
            must: [
              {
                'query_string' => { 'query' => 'id:0' }
              },
            ],
          }
        }
      end

      {
        bool: {
          must: [
            {
              bool: {
                should: query_or,
              },
            },
          ],
        }
      }
    end

    def search_query_condition(params)
      return if params[:query].blank?
      return if !search_customer_access?(params)

      query_or = [search_query_condition_customer(params)]

      group_ids = search_agent_group_ids(params)
      if group_ids.present?
        query_or.push(
          {
            bool: {
              must: [
                { terms: { group_id: group_ids } },
                SearchIndexBackend.build_query_condition(params[:query], name, params),
              ],
            }
          }
        )
      end

      {
        bool: {
          should: query_or,
        }
      }
    end

    def search_query_condition_customer(params)
      {
        bool: {
          should: [
            search_query_condition_fields(search_query_condition_customer_query(params[:query]), CUSTOMER_SEARCH_FIELDS),
            {
              nested: {
                path:  'article',
                query: {
                  bool: {
                    must:   [search_query_condition_fields(params[:query], CUSTOMER_SEARCH_ARTICLE_FIELDS)],
                    filter: [{ term: { 'article.internal' => false } }],
                  }
                }
              }
            },
          ],
        }
      }
    end

    # Field syntax stays available for the customer visible fields and the id, all other field references become literal text.
    def search_query_condition_customer_query(query)
      query.gsub(%r{([\w.*?\\]*)(?<!\\):}) do
        field = Regexp.last_match(1)
        CUSTOMER_SEARCH_SYNTAX_FIELDS.include?(field) ? "#{field}:" : "#{field}\\:"
      end
    end

    def search_query_condition_fields(query, fields)
      SearchIndexBackend.build_query_condition(query, name, query_fields_by_indexes: { name.to_sym => fields })
    end
  end
end
