# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'active_record/connection_adapters/postgresql/schema_statements'

module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module SchemaStatements

        # On postgres create lower indices to support case-insensitive where conditions.
        def quoted_columns_for_index(column_names, options) # :nodoc:
          quoted_columns = column_names.each_with_object({}) do |name, result|
            ## PATCH start
            if name =~ %r{^(name|login|locale|alias)$} || name.end_with?('name')
              result[name.to_sym] = "LOWER(#{quote_column_name(name).dup})"
              next
            end
            ## PATCH end
            result[name.to_sym] = quote_column_name(name).dup
          end
          add_options_for_index_columns(quoted_columns, **options).values.join(', ')
        end

      end
    end
  end
end
