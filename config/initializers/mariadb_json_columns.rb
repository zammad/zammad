# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
  # INFORMATION_SCHEMA.CHECK_CONSTRAINTS is only support on > 10.4 mariadb
  # so we use object manager attributes table now to detect them.
  def mariadb_column_json?(table_name, field_name)
    field = quote(field_name)
    scope = quoted_scope(table_name)

    # for older versions
    if database_version < '10.4' && %w[tickets users groups organizations].include?(table_name)
      class_name = table_name.classify
      execute_and_free("SELECT 1 FROM object_manager_attributes, object_lookups WHERE object_manager_attributes.object_lookup_id = object_lookups.id AND object_lookups.name = '#{class_name}' AND object_manager_attributes.name = #{field} AND object_manager_attributes.data_type IN ('multiselect', 'multi_tree_select') LIMIT 1") do |r|
        return r.to_a.present?
      end
    end

    execute_and_free("SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE TABLE_NAME = #{scope[:name]} AND CONSTRAINT_SCHEMA = #{scope[:schema]} AND CONSTRAINT_NAME = #{field} AND CHECK_CLAUSE LIKE '%json_valid%'") do |r|
      return r.to_a.present?
    end
  end
end
