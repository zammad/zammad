# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase
  module Search
    extend ActiveSupport::Concern

    class_methods do
      def search(params)
        current_user = params[:current_user]
        # enable search only for agents and admins
        return [] if !search_preferences(current_user)

        sql_helper = ::SqlHelper.new(object: self)

        options = {
          limit:    params[:limit] || 10,
          from:     params[:offset] || 0,
          sort_by:  sql_helper.get_sort_by(params, 'updated_at'),
          order_by: sql_helper.get_order_by(params, 'desc'),
          user:     current_user
        }

        kb_locales = KnowledgeBase.active.map { |elem| KnowledgeBase::Locale.preferred(current_user, elem) }

        # try search index backend
        if SearchIndexBackend.enabled?
          search_es(params[:query], kb_locales, options)
        else
          # fallback do sql query
          search_sql(params[:query], kb_locales, options)
        end
      end

      def search_es(query, kb_locales, options)
        options[:query_extension] = { bool: { filter: { terms: { kb_locale_id: kb_locales.map(&:id) } } } }

        es_response = SearchIndexBackend.search(query, name, options)
        es_response = search_es_filter(es_response, query, kb_locales, options) if defined? :search_es_filter

        es_response.map { |item| lookup(id: item[:id]) }.compact
      end

      def search_sql(query, kb_locales, options)
        table_name = arel_table.name
        sql_helper = ::SqlHelper.new(object: self)
        order_sql  = sql_helper.get_order(options[:sort_by], options[:order_by], "#{table_name}.updated_at ASC")

        # - stip out * we already search for *query* -
        query.delete! '*'

        search_fallback("%#{query}%", options: options)
          .where(kb_locale: kb_locales)
          .order(Arel.sql(order_sql))
          .offset(options[:from])
          .limit(options[:limit])
          .to_a
      end
    end
  end
end
