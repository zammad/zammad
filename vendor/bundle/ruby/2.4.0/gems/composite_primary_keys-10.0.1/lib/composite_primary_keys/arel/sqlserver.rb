module Arel
  module Visitors
    class SQLServer
      def make_Fetch_Possible_And_Deterministic o
        return if o.limit.nil? && o.offset.nil?
        t = table_From_Statement o
        pk = primary_Key_From_Table t
        return unless pk
        if o.orders.empty?
          # Prefer deterministic vs a simple `(SELECT NULL)` expr.
          # CPK
          #o.orders = [pk.asc]
          o.orders = pk.map {|a_pk| a_pk.asc}
        end
      end

      def primary_Key_From_Table t
        return unless t
        column_name = @connection.schema_cache.primary_keys(t.name) ||
          @connection.schema_cache.columns_hash(t.name).first.try(:second).try(:name)

        # CPK
        # column_name ? t[column_name] : nil
        case column_name
          when Array
            column_name.map do |name|
              t[name]
            end
          when NilClass
            nil
          else
            [t[column_name]]
        end
      end
    end
  end
end
