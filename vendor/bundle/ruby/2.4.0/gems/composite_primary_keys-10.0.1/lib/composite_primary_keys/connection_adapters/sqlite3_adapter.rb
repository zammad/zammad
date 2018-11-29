module ActiveRecord
  module ConnectionAdapters
    class SQLite3Adapter
      def join_to_update(update, select, key)
        if key.is_a?(::CompositePrimaryKeys::CompositeKeys)
          subselect = subquery_for(key, select)
          subselect_aliased = Arel::Nodes::TableAlias.new(subselect, 'cpk_inner')
          cpk_subselect = Arel::SelectManager.new(subselect_aliased)
          cpk_subselect.project('*')
          key.each do |a_key|
            where_expr = subselect_aliased[a_key.name].eq(update.ast.relation[a_key.name])
            cpk_subselect.where(where_expr)
          end
          where_clause = Arel::Nodes::SqlLiteral.new("EXISTS (#{cpk_subselect.to_sql})")
          update.where(where_clause)
        else
          super
        end
      end
      alias join_to_delete join_to_update
    end
  end
end