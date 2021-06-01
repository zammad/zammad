# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'active_record/connection_adapters/postgresql/schema_statements'

module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module SchemaStatements

        # on postgres create lower indices to support case-insensitive where conditions
        def add_index(table_name, column_name, options = {}) #:nodoc:
          index_name, index_type, index_columns, index_options, index_algorithm, index_using = add_index_options(table_name, column_name, options)

          column_names = index_columns.split ', '
          if column_names.instance_of?(Array)
            index_columns_new = []
            column_names.each do |i|
              if i =~ %r{^"(name|login|locale|alias)"$} || i.end_with?('name"')
                index_columns_new.push "LOWER(#{i})"
              else
                index_columns_new.push i
              end
            end
            index_columns = index_columns_new.join ', '
          end

          execute "CREATE #{index_type} INDEX #{index_algorithm} #{quote_column_name(index_name)} ON #{quote_table_name(table_name)} #{index_using} (#{index_columns})#{index_options}"

        end
      end
    end
  end
end
