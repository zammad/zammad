# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SqlHelper

  def initialize(object:)
    @object = object
  end

  def get_param_key(key, params)
    sort_by = []
    if params[key].present? && params[key].is_a?(String)
      params[key] = params[key].split(%r{\s*,\s*})
    elsif params[key].blank?
      params[key] = []
    end

    sort_by
  end

=begin

This function will check the params for the "sort_by" attribute
and validate its values.

  sql_helper = SqlHelper.new(object: Ticket)
  sort_by    = sql_helper.get_sort_by(params, default)

returns

  sort_by = [
    'created_at',
    'updated_at',
  ]

=end

  def get_sort_by(params, default = nil)
    sort_by = get_param_key(:sort_by, params)

    # check order
    params[:sort_by].each do |value|

      # only accept values which are set for the db schema
      raise "Found invalid column '#{value}' for sorting." if @object.columns_hash[value].blank?

      sort_by.push(value)
    end

    if sort_by.blank? && default.present?
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

sql_helper = SqlHelper.new(object: Ticket)
order_by   = sql_helper.get_order_by(params, default)

returns

order_by = [
  'asc',
  'desc',
]

=end

  def get_order_by(params, default = nil)
    order_by = get_param_key(:order_by, params)

    # check order
    params[:order_by].each do |value|
      raise "Found invalid order by value #{value}. Please use 'asc' or 'desc'." if !value.match?(%r{\A(asc|desc)\z}i)

      order_by.push(value.downcase)
    end

    if order_by.blank? && default.present?
      if default.is_a?(Array)
        order_by = default
      else
        order_by.push(default)
      end
    end

    order_by
  end

  def set_sql_order_default(sql, default)
    if sql.blank? && default.present?
      sql.push("#{ActiveRecord::Base.connection.quote_table_name(@object.table_name)}.#{ActiveRecord::Base.connection.quote_column_name(default)}")
    end
    sql
  end

=begin

This function will use the evaluated values for sort_by and
order_by to generate the ORDER-SELECT sql statement for the sorting
of the result.

sort_by  = [ 'created_at', 'updated_at' ]
order_by = [ 'asc', 'desc' ]
default  = 'tickets.created_at'

sql_helper = SqlHelper.new(object: Ticket)
sql        = sql_helper.get_order_select(sort_by, order_by, default)

returns

sql = 'tickets.created_at, tickets.updated_at'

=end

  def get_order_select(sort_by, order_by, default = nil)
    sql = []

    sort_by.each_with_index do |value, index|
      next if value.blank?
      next if order_by[index].blank?

      sql.push( "#{ActiveRecord::Base.connection.quote_table_name(@object.table_name)}.#{ActiveRecord::Base.connection.quote_column_name(value)}" )
    end

    sql = set_sql_order_default(sql, default)

    sql.join(', ')
  end

=begin

This function will use the evaluated values for sort_by and
order_by to generate the ORDER- sql statement for the sorting
of the result.

sort_by  = [ 'created_at', 'updated_at' ]
order_by = [ 'asc', 'desc' ]
default  = 'tickets.created_at DESC'

sql_helper = SqlHelper.new(object: Ticket)
sql        = sql_helper.get_order(sort_by, order_by, default)

returns

sql = 'tickets.created_at ASC, tickets.updated_at DESC'

=end

  def get_order(sort_by, order_by, default = nil)
    sql = []

    sort_by.each_with_index do |value, index|
      next if value.blank?
      next if order_by[index].blank?

      sql.push( "#{ActiveRecord::Base.connection.quote_table_name(@object.table_name)}.#{ActiveRecord::Base.connection.quote_column_name(value)} #{order_by[index]}" )
    end

    sql = set_sql_order_default(sql, default)

    sql.join(', ')
  end
end
