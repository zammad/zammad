# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module CanSearch
  extend ActiveSupport::Concern

  included do

=begin

This function provides the possibility to add model specific sql extensions
for the searches in the DB. E.g. role or group specific conditions
in user model.

see e.g. also app/models/user/search.rb

=end

    scope :search_sql_extension, ->(_params) {}

=begin

This function defines the sql search query for the text fields which are searched in. By default
it is all string columns but can be modified.

see e.g. also app/models/ticket/search.rb

=end

    scope :search_sql_query_extension, lambda { |params|
      return if params[:query].blank?

      search_columns = columns.select { |row| row.type == :string && !row.try(:array) }.map(&:name)
      return if search_columns.blank?

      where_or_cis(search_columns, "%#{SqlHelper.quote_like(params[:query].to_s.downcase)}%")
    }

    # Scope to specific IDs if they're given in params.
    # Usually those IDs are pre-filled in .search_params_pre method.
    scope :search_sql_ids, lambda { |params|
      where(id: params[:ids]) if params[:ids].present?
    }
  end

  class_methods do

=begin

This defines the default search sort by for the search function.

=end

    def search_default_sort_by
      'updated_at'
    end

=begin

This defines the default search order by for the search function.

=end

    def search_default_order_by
      'desc'
    end

=begin

This function can be used to fix parameters for the model
e.g. is used to restrict the result set of organization searches
to only return customer organizations in case of a customer user

see e.g. also app/models/organization/search.rb

=end

    def search_params_pre(params)
      # optional
    end

=begin

This function provides the possibility to add model specific query extensions
for the searches in the elasticsearch. E.g. role or group specific conditions
in user model.

see e.g. also app/models/user/search.rb

=end

    def search_query_extension(params)
      # optional
    end

=begin

search objects via search index

  result = Model.search(
    current_user: User.find(123),
    query:        'search something',
    limit:        15,
    offset:       100,
  )

returns

  result = [obj1, obj2, obj3]

search objects via search index with total count

  result = Model.search(
    current_user: User.find(123),
    query:            'search something',
    limit:            15,
    offset:           100,
    with_total_count: true
  )

returns

  result = {
    object_ids: [1,2,3],
    count: 3,
  }

search objects via search index with ONLY total count

  result = Model.search(
    current_user: User.find(123),
    query:            'search something',
    limit:            15,
    offset:           100,
    only_total_count: true
  )

returns

  result = {
    count: 3,
  }

search objects via search index

  result = Model.search(
    current_user: User.find(123),
    query:        'search something',
    limit:        15,
    offset:       100,
    full:         false,
  )

returns

  result = [1,2,3]

search objects via database

  result = Group.search(
    current_user: User.find(123),
    query: 'some query', # query or condition is required
    condition: {
      'groups.id' => {
        operator: 'is',
        value: [1,2,3],
      },
    },
    limit: 15,
    offset: 100,

    # sort single column
    sort_by: 'created_at',
    order_by: 'asc',

    # sort multiple columns
    sort_by: [ 'created_at', 'updated_at' ],
    order_by: [ 'asc', 'desc' ],

    full: false,
  )

returns

  result = [1,2,3]

=end

    def search(params)
      # It's possible to search objects that don't have .search_preferences method.
      # However, if .search_preferences exist and return falsey value, search is not authorized in a given context!
      # Thus we need to check if method exist instead of using try()!
      return if defined?(search_preferences) && !search_preferences(params[:current_user])

      params = search_build_params(params)

      # try search index backend
      # we only search in elastic search when we have a query present
      # else we try to use the database result, since it is more up to date
      object_ids, object_count = if SearchIndexBackend.enabled? && included_modules.include?(HasSearchIndexBackend) && params[:query].present?
                                   search_es(params)
                                 else
                                   search_sql(params)
                                 end

      search_result(params, object_ids, object_count)
    end

    def search_result(params, object_ids, object_count)
      if params[:only_total_count].present?
        {
          total_count: object_count,
        }
      elsif params[:with_total_count].present?
        if params[:full].present?
          return {
            objects:     where_ordered_ids(object_ids),
            total_count: object_count
          }
        end

        {
          object_ids:  object_ids,
          total_count: object_count
        }
      elsif params[:full].present?
        where_ordered_ids(object_ids)
      else
        object_ids
      end
    end

    def search_build_params(params)
      search_params_pre(params)

      sql_helper = ::SqlHelper.new(object: self)

      params[:condition] ||= {}
      params[:limit]     ||= 50
      params[:query]    = params[:query]&.delete('*')
      params[:offset]   = params[:offset].presence || params[:from].presence || 0
      params[:full]     = !params.key?(:full) || ActiveModel::Type::Boolean.new.cast(params[:full])
      params[:sort_by]  = sql_helper.get_sort_by(params, search_default_sort_by)
      params[:order_by] = sql_helper.get_order_by(params, search_default_order_by)

      params
    end

    def search_es(params)
      result = SearchIndexBackend.search_by_index(
        params[:query],
        to_s,
        params.merge(query_extension: search_query_extension(params), with_total_count: true)
      )

      if params[:only_total_count].blank?
        object_ids = result&.dig(:object_metadata)&.pluck(:id) || []
      end

      object_count = result&.dig(:total_count) || 0

      [object_ids, object_count]
    end

    def search_sql(params)
      scope = search_sql_base(params)

      objects_order_sql = sql_helper.get_order(params[:sort_by], params[:order_by], "#{table_name}.updated_at DESC")

      objects_scope = scope
        .reorder(Arel.sql(objects_order_sql))
        .offset(params[:offset])
        .limit(params[:limit])
        .group(:id)

      if params[:only_total_count].blank?
        object_ids = objects_scope.pluck(:id)
      end

      object_count = scope.count("DISTINCT #{table_name}.id")

      [object_ids, object_count]
    end

    def search_sql_base(params)
      query_condition, bind_condition, tables = selector2sql(params[:condition])

      scope = params[:scope].present? ? params[:scope].new(params[:current_user]).resolve : all

      scope
        .joins(tables).where(query_condition, *bind_condition)
        .search_sql_extension(params)
        .search_sql_query_extension(params)
        .search_sql_ids(params)
    end

    def sql_helper
      @sql_helper ||= ::SqlHelper.new(object: self)
    end

    #
    # Returns a relation with objects referenced by the ids in their original order.
    #
    def where_ordered_ids(ids)
      order_by = case ActiveRecord::Base.connection_db_config.configuration_hash[:adapter]
                 when 'postgresql'
                   "array_position(ARRAY[#{ids.join(',')}], id)"
                 when 'mysql2'
                   "FIELD(id, #{ids.join(',')})"
                 end
      where(id: ids).reorder(Arel.sql(order_by))
    end
  end
end
