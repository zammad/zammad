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
          order_by: search_get_order_by(params, 'desc')
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

        SearchIndexBackend
          .search(query, name, options)
          .map { |item| lookup(id: item[:id]) }
          .compact
      end

      def search_sql(query, kb_locale, options)
        table_name       = arel_table.name
        order_sql        = search_get_order_sql(options[:sort_by], options[:order_by], "#{table_name}.updated_at ASC")

        # - stip out * we already search for *query* -
        query.delete! '*'

        search_fallback("%#{query}%")
          .where(kb_locale: kb_locale)
          .order(order_sql)
          .offset(options[:from])
          .limit(options[:limit])
          .to_a
      end
    end
  end
end
