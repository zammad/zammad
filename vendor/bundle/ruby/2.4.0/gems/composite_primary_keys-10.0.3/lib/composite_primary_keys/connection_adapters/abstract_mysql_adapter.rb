module ActiveRecord
  module ConnectionAdapters
    class AbstractMysqlAdapter
      def subquery_for(key, select)
        subsubselect = select.clone
        subsubselect.projections = [key]

        # Materialize subquery by adding distinct
        # to work with MySQL 5.7.6 which sets optimizer_switch='derived_merge=on'
        subsubselect.distinct unless select.limit || select.offset || select.orders.any?

        subselect = Arel::SelectManager.new(select.engine)

        # CPK
        #subselect.project Arel.sql(key.name)
        subselect.project Arel.sql(Array(key).map(&:name).join(', '))

        subselect.from subsubselect.as('__active_record_temp')
      end
    end
  end
end
