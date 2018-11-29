module CompositePrimaryKeys
  module ActiveRecord
    module QueryMethods
      def reverse_sql_order(order_query)
        # CPK
        # order_query = ["#{quoted_table_name}.#{quoted_primary_key} ASC"] if order_query.empty?

        # break apart CPKs
        order_query = primary_key.map do |key|
          "#{quoted_table_name}.#{connection.quote_column_name(key)} ASC"
        end if order_query.empty?

        order_query.map do |o|
          case o
            when Arel::Nodes::Ordering
              o.reverse
            when String, Symbol
              o.to_s.split(',').collect do |s|
                s.strip!
                s.gsub!(/\sasc\Z/i, ' DESC') || s.gsub!(/\sdesc\Z/i, ' ASC') || s.concat(' DESC')
              end
            else
              o
          end
        end.flatten
      end
    end
  end
end

