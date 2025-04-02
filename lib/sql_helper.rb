# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SqlHelper

  def self.quote_string(value)
    ActiveRecord::Base.connection.quote_string(value)
  end

  def self.quote_like(...)
    ApplicationModel.sanitize_sql_like(...)
  end

  def initialize(object:, table_name: nil)
    @object     = object
    @table_name = table_name
  end

  def db_column(column)
    "#{ActiveRecord::Base.connection.quote_table_name(@table_name || @object.table_name)}.#{ActiveRecord::Base.connection.quote_column_name(column)}"
  end

  def json_column?(attribute)
    @object.column_for_attribute(attribute).type == :jsonb
  end

  def json_db_column_with_key(attribute, key)
    "#{db_column(attribute)}->>#{ActiveRecord::Base.connection.quote(key)}"
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
      sql.push(db_column(default))
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

      sql.push(db_column(value))
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

      sql.push("#{db_column(value)} #{order_by[index]}")
    end

    sql = set_sql_order_default(sql, default)

    sql.join(', ')
  end

  def containable?(attribute)
    ObjectManager::Attribute.for_object(@object).exists?(name: attribute, data_type: %w[multiselect multi_tree_select])
  end

  def array_contains_all(attribute, value, negated: false)
    value = [''] if value.blank?
    value = Array(value)
    result = if Rails.application.config.db_column_array
               "(#{db_column(attribute)} @> ARRAY[#{value.map { |v| "'#{self.class.quote_string(v)}'" }.join(',')}]::varchar[])"
             else
               "JSON_CONTAINS(#{db_column(attribute)}, '#{self.class.quote_string(value.to_json)}', '$')"
             end
    negated ? "NOT(#{result})" : "(#{result})"
  end

  def array_contains_one(attribute, value, negated: false)
    value = [''] if value.blank?
    value = Array(value)
    result = if Rails.application.config.db_column_array
               "(#{db_column(attribute)} && ARRAY[#{value.map { |v| "'#{self.class.quote_string(v)}'" }.join(',')}]::varchar[])"
             else
               value.map { |v| "JSON_CONTAINS(#{db_column(attribute)}, '#{self.class.quote_string(v.to_json)}', '$')" }.join(' OR ')
             end
    negated ? "NOT(#{result})" : "(#{result})"
  end

  def regex_match(attribute, negated: false)
    operator = if mysql?
                 negated ? 'NOT REGEXP' : 'REGEXP'
               else
                 negated ? '!~*' : '~*'
               end

    "#{attribute} #{operator} (?)"
  end

  private

  def mysql?
    ActiveRecord::Base.connection_db_config.configuration_hash[:adapter] == 'mysql2'
  end
end
