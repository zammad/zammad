module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module DatabaseStatements
        def sql_for_insert(sql, pk, id_value, sequence_name, binds) # :nodoc:
          if pk.nil?
            # Extract the table from the insert sql. Yuck.
            table_ref = extract_table_ref_from_insert_sql(sql)
            pk = primary_key(table_ref) if table_ref
          end

          # CPK
          # if pk = suppress_composite_primary_key(pk)
          #  sql = "#{sql} RETURNING #{quote_column_name(pk)}"
          #end
          # NOTE pk can be false.
          if pk
            sql = "#{sql} RETURNING #{quote_column_names(pk)}"
          end

          super
        end
      end
    end
  end
end
