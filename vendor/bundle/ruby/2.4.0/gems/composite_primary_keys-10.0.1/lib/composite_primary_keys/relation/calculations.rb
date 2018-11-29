module CompositePrimaryKeys
  module ActiveRecord
    module Calculations
      def aggregate_column(column_name)
        # CPK
        if column_name.kind_of?(Array)
          column_name.map do |column|
            Arel::Attribute.new(@klass.unscoped.table, column)
          end
        elsif @klass.column_names.include?(column_name.to_s)
          Arel::Attribute.new(@klass.unscoped.table, column_name)
        else
          Arel.sql(column_name == :all ? "*" : column_name.to_s)
        end
      end

      def execute_simple_calculation(operation, column_name, distinct) #:nodoc:
        # PostgreSQL doesn't like ORDER BY when there are no GROUP BY
        relation = unscope(:order)

        column_alias = column_name

        # CPK
        # if operation == "count" && (relation.limit_value || relation.offset_value)
        if operation == "count"
          # Shortcut when limit is zero.
          return 0 if relation.limit_value == 0

          query_builder = build_count_subquery(relation, column_name, distinct)
        else
          column = aggregate_column(column_name)

          select_value = operation_over_aggregate_column(column, operation, distinct)

          column_alias = select_value.alias
          column_alias ||= @klass.connection.column_name_for_operation(operation, select_value)
          relation.select_values = [select_value]

          query_builder = relation.arel
        end

        result = @klass.connection.select_all(query_builder, nil, bound_attributes)
        row    = result.first
        value  = row && row.values.first
        column = result.column_types.fetch(column_alias) do
          type_for(column_name)
        end

        type_cast_calculated_value(value, column, operation)
      end

      def build_count_subquery(relation, column_name, distinct)
        return super(relation, column_name, distinct) unless column_name.kind_of?(Array)
        # CPK
        # column_alias = Arel.sql('count_column')
        subquery_alias = Arel.sql('subquery_for_count')

        # CPK
        # aliased_column = aggregate_column(column_name == :all ? 1 : column_name).as(column_alias)
        # relation.select_values = [aliased_column]
        relation.select_values = column_name.map do |column|
          Arel::Attribute.new(@klass.unscoped.table, column)
        end

        relation = relation.distinct(true)
        subquery = relation.arel.as(subquery_alias)

        sm = Arel::SelectManager.new relation.engine
        sm.bind_values = relation.arel.bind_values
        # CPK
        # select_value = operation_over_aggregate_column(column_alias, 'count', distinct)
        select_value = operation_over_aggregate_column(Arel.sql("*"), 'count', false)
        sm.project(select_value).from(subquery)
      end
    end
  end
end
