# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'active_record/relation/calculations'

module ActiveRecord
  module Calculations
    # counts the rows the relation returns, in the database, also when it is grouped
    #   (a grouped count(:all) returns a hash with one entry per group instead)
    #
    # @see ActiveRecord::Calculations#count
    #
    # @return [Integer]
    #
    # @example
    #   Ticket.all.count_rows # 3
    #   Ticket.joins(:articles).group('tickets.id').count_rows # 3
    def count_rows
      relation = unscope(:order)
      return relation.count(:all) if relation.group_values.empty?

      # Without DISTINCT, and when every group value is a qualified column (never an alias of the select list),
      #   the wide select list does not decide the number of groups, so it is dropped.
      relation = relation.reselect(Arel.sql('1')) if !distinct_value && relation.count_rows_grouped_by_qualified_columns?
      model.unscoped.from(relation, :counted_rows).count(:all)
    end

    COUNT_ROWS_QUALIFIED_COLUMN = %r{\A(?:"[^"]+"|[a-z_]\w*)(?:\.(?:"[^"]+"|[a-z_]\w*))+\z}i

    protected

    # Called on the fresh relation of #count_rows: resolving the group values modifies the relation,
    #   which one that was loaded or has built its SQL does not allow.
    def count_rows_grouped_by_qualified_columns?
      with_connection do |connection|
        arel_columns(group_values)
          .flat_map { |column| connection.visitor.compile(column).split(',') }
          .all? { |column| column.strip.match?(COUNT_ROWS_QUALIFIED_COLUMN) }
      end
    end
  end
end
