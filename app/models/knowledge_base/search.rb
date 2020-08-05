class KnowledgeBase
  module Search
    extend ActiveSupport::Concern

    included do
      include HasSearchSortable
    end

    class_methods do
      def search(params)
        current_user = params[:current_user]
        # enable search only for agents and admins
        return [] if !search_preferences(current_user)

        options = {
          limit:    params[:limit] || 10,
          from:     params[:offset] || 0,
          sort_by:  search_get_sort_by(params, 'updated_at'),
          order_by: search_get_order_by(params, 'desc'),
          user:     current_user
        }

        kb_locale = KnowledgeBase::Locale.preferred(current_user, KnowledgeBase.first)

        # try search index backend
        if SearchIndexBackend.enabled?
          search_es(params[:query], kb_locale, options)
        else
          # fallback do sql query
          search_sql(params[:query], kb_locale, options)
        end
      end

      def search_es(query, kb_locale, options)
        options[:query_extension] = { bool: { filter: { term: { kb_locale_id: kb_locale.id } } } }

        es_response = SearchIndexBackend.search(query, name, options)
        es_response = search_es_filter(es_response, query, kb_locale, options) if defined? :search_es_filter

        es_response.map { |item| lookup(id: item[:id]) }.compact
      end

      def search_sql(query, kb_locale, options)
        table_name       = arel_table.name
        order_sql        = search_get_order_sql(options[:sort_by], options[:order_by], "#{table_name}.updated_at ASC")

        # - stip out * we already search for *query* -
        query.delete! '*'

        search_fallback("%#{query}%", options: options)
          .where(kb_locale: kb_locale)
          .order(Arel.sql(order_sql))
          .offset(options[:from])
          .limit(options[:limit])
          .to_a
      end
    end
  end
end
