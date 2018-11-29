module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter
      def quote_column_names(name)
        Array(name).map do |col|
          quote_column_name(col.to_s)
        end.join(CompositePrimaryKeys::ID_SEP)
      end
    end
  end
end