module ActiveRecord
  module ConnectionAdapters
    class SQLServerAdapter
      def sql_for_insert(sql, pk, id_value, sequence_name, binds)
        sql = if pk && self.class.use_output_inserted
          # CPK
          # quoted_pk = SQLServer::Utils.extract_identifiers(pk).quoted
          # sql.insert sql.index(/ (DEFAULT )?VALUES/), " OUTPUT INSERTED.#{quoted_pk}"
          quoted_pks = [pk].flatten.map {|pk| "INSERTED.#{SQLServer::Utils.extract_identifiers(pk).quoted}"}
          sql.insert sql.index(/ (DEFAULT )?VALUES/), " OUTPUT #{quoted_pks.join(", ")}"
        else
          "#{sql}; SELECT CAST(SCOPE_IDENTITY() AS bigint) AS Ident"
        end

        # CPK
        # super
        [sql, binds]
      end
    end
  end
end
