# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module HasSearchSortable
  extend ActiveSupport::Concern

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

=begin

This function will check the params for the "sort_by" attribute
and validate its values.

  sort_by = search_get_sort_by(params, default)

returns

  sort_by = [
    'created_at',
    'updated_at',
  ]

=end

    def search_get_sort_by(params, default)
      sort_by = []
      if params[:sort_by].present? && params[:sort_by].is_a?(String)
        params[:sort_by] = [params[:sort_by]]
      elsif params[:sort_by].blank?
        params[:sort_by] = []
      end

      # check order
      params[:sort_by].each do |value|

        # only accept values which are set for the db schema
        raise "Found invalid column '#{value}' for sorting." if columns_hash[value].blank?

        sort_by.push(value)
      end

      if sort_by.blank?
        if default.is_a?(Array)
          sort_by = default
        else
          sort_by.push(default)
        end
      end

      sort_by
    end

=begin

This function will check the params for the "order_by" attribute
and validate its values.

  order_by = search_get_order_by(params, default)

returns

  order_by = [
    'asc',
    'desc',
  ]

=end

    def search_get_order_by(params, default)
      order_by = []
      if params[:order_by].present? && params[:order_by].is_a?(String)
        params[:order_by] = [ params[:order_by] ]
      elsif params[:order_by].blank?
        params[:order_by] = []
      end

      # check order
      params[:order_by].each do |value|
        raise "Found invalid order by value #{value}. Please use 'asc' or 'desc'." if !value.match?(/\A(asc|desc)\z/i)

        order_by.push(value.downcase)
      end

      if order_by.blank?
        if default.is_a?(Array)
          order_by = default
        else
          order_by.push(default)
        end
      end

      order_by
    end

=begin

This function will use the evaluated values for sort_by and
order_by to generate the ORDER-SELECT sql statement for the sorting
of the result.

  sort_by  = [ 'created_at', 'updated_at' ]
  order_by = [ 'asc', 'desc' ]
  default  = 'tickets.created_at'

  sql = search_get_order_select_sql(sort_by, order_by, default)

returns

  sql = 'tickets.created_at, tickets.updated_at'

=end

    def search_get_order_select_sql(sort_by, order_by, default)
      sql = []

      sort_by.each_with_index do |value, index|
        next if value.blank?
        next if order_by[index].blank?

        sql.push( "#{ActiveRecord::Base.connection.quote_table_name(table_name)}.#{ActiveRecord::Base.connection.quote_column_name(value)}" )
      end

      if sql.blank?
        sql.push("#{ActiveRecord::Base.connection.quote_table_name(table_name)}.#{ActiveRecord::Base.connection.quote_column_name(default)}")
      end

      sql.join(', ')
    end

=begin

This function will use the evaluated values for sort_by and
order_by to generate the ORDER- sql statement for the sorting
of the result.

  sort_by  = [ 'created_at', 'updated_at' ]
  order_by = [ 'asc', 'desc' ]
  default  = 'tickets.created_at DESC'

  sql = search_get_order_sql(sort_by, order_by, default)

returns

  sql = 'tickets.created_at ASC, tickets.updated_at DESC'

=end

    def search_get_order_sql(sort_by, order_by, default)
      sql = []

      sort_by.each_with_index do |value, index|
        next if value.blank?
        next if order_by[index].blank?

        sql.push( "#{ActiveRecord::Base.connection.quote_table_name(table_name)}.#{ActiveRecord::Base.connection.quote_column_name(value)} #{order_by[index]}" )
      end

      if sql.blank?
        sql.push("#{ActiveRecord::Base.connection.quote_table_name(table_name)}.#{ActiveRecord::Base.connection.quote_column_name(default)}")
      end

      sql.join(', ')
    end

  end

end
