# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'active_record/connection_adapters/abstract_mysql_adapter'

ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.class_eval do
  private

  alias_method :column_definitions_original, :column_definitions

  def column_definitions(table_name)
    result = column_definitions_original(table_name)
    if mariadb?
      result.each do |row|
        next if row[:Type] != 'longtext'
        next if !mariadb_column_json?(table_name, row[:Field])

        row[:Type] = 'json'
      end
    end
    result
  end

  # https://github.com/zammad/zammad/issues/4148
  # JSON columns in mariadb are listed as longtext, so we need to check
  # the constraint checks to find out if the column was created as json.
  # Based on this detection we will hack the type so rails will handle
  # values properly as json values.
  def mariadb_column_json?(table_name, field_name)
    field = quote(field_name)
    scope = quoted_scope(table_name)
    execute_and_free("SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE TABLE_NAME = #{scope[:name]} AND CONSTRAINT_SCHEMA = #{scope[:schema]} AND CONSTRAINT_NAME = #{field} AND CHECK_CLAUSE LIKE '%json_valid%'") do |r|
      return r.to_a.present?
    end
  end
end
