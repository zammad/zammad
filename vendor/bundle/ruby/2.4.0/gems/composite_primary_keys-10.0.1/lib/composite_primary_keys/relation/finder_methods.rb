module CompositePrimaryKeys
  module ActiveRecord
    module FinderMethods
      def apply_join_dependency(relation, join_dependency)
        relation = relation.except(:includes, :eager_load, :preload)
        relation = relation.joins join_dependency

        if using_limitable_reflections?(join_dependency.reflections)
          relation
        else
          if relation.limit_value
            limited_ids = limited_ids_for(relation)
            # CPK
            # limited_ids.empty? ? relation.none! : relation.where!(table[primary_key].in(limited_ids))
            limited_ids.empty? ? relation.none! : relation.where!(cpk_in_predicate(table, self.primary_keys, limited_ids))
          end
          relation.except(:limit, :offset)
        end
      end

      def limited_ids_for(relation)
        # CPK
        # values = @klass.connection.columns_for_distinct(
        #     "#{quoted_table_name}.#{quoted_primary_key}", relation.order_values)
        columns = @klass.primary_keys.map do |key|
          "#{quoted_table_name}.#{connection.quote_column_name(key)}"
        end
        values = @klass.connection.columns_for_distinct(columns, relation.order_values)

        relation = relation.except(:select).select(values).distinct!
        arel = relation.arel

        id_rows = @klass.connection.select_all(arel, 'SQL', relation.bound_attributes)

        # CPK
        #id_rows.map {|row| row[primary_key]}
        id_rows.map {|row| row.values}
      end

      def exists?(conditions = :none)
        if ::ActiveRecord::Base === conditions
          conditions = conditions.id
          ActiveSupport::Deprecation.warn(<<-MSG.squish)
          You are passing an instance of ActiveRecord::Base to `exists?`.
          Please pass the id of the object by calling `.id`
          MSG
        end

        return false if !conditions

        relation = apply_join_dependency(self, construct_join_dependency)
        return false if ::ActiveRecord::NullRelation === relation

        relation = relation.except(:select, :order).select(::ActiveRecord::FinderMethods::ONE_AS_ONE).limit(1)

        case conditions
          # CPK
          when CompositePrimaryKeys::CompositeKeys
            relation = relation.where(cpk_id_predicate(table, primary_key, conditions))
          # CPK
          when Array
            pk_length = @klass.primary_keys.length

            if conditions.length == pk_length # E.g. conditions = ['France', 'Paris']
              return self.exists?(conditions.to_composite_keys)
            else # Assume that conditions contains where relation
              relation = relation.where(conditions)
            end
          when Array, Hash
            relation = relation.where(conditions)
          else
            unless conditions == :none
              relation = relation.where(primary_key => conditions)
            end
        end

        connection.select_value(relation, "#{name} Exists", relation.bound_attributes) ? true : false
      end

      def find_with_ids(*ids)
        raise UnknownPrimaryKey.new(@klass) if primary_key.nil?

        # CPK
        # expects_array = ids.first.kind_of?(Array)
        ids = CompositePrimaryKeys.normalize(ids)
        expects_array = ids.flatten != ids.flatten(1)
        return ids.first if expects_array && ids.first.empty?

        # CPK
        # ids = ids.flatten.compact.uniq
        ids = expects_array ? ids.first : ids

        case ids.size
          when 0
            raise RecordNotFound, "Couldn't find #{@klass.name} without an ID"
          when 1
            result = find_one(ids.first)
            expects_array ? [ result ] : result
          else
            find_some(ids)
        end
      rescue RangeError
        raise RecordNotFound, "Couldn't find #{@klass.name} with an out of range ID"
      end

      def last(limit = nil)
        return find_last(limit) if loaded? || limit_value

        result = limit(limit || 1)
        # CPK
        # result.order!(arel_attribute(primary_key)) if order_values.empty? && primary_key
        if order_values.empty? && primary_key
          if composite?
            result.order!(primary_keys.map { |pk| arel_attribute(pk).asc })
          elsif
            result.order!(arel_attribute(primary_key))
          end
        end

        result = result.reverse_order!

        limit ? result.reverse : result.first
      rescue ::ActiveRecord::IrreversibleOrderError
        ActiveSupport::Deprecation.warn(<<-WARNING.squish)
            Finding a last element by loading the relation when SQL ORDER
            can not be reversed is deprecated.
            Rails 5.1 will raise ActiveRecord::IrreversibleOrderError in this case.
            Please call `to_a.last` if you still want to load the relation.
        WARNING
        find_last(limit)
      end


      def find_nth_with_limit(index, limit)
        # TODO: once the offset argument is removed from find_nth,
        # find_nth_with_limit_and_offset can be merged into this method
        #
        # CPK
        # relation = if order_values.empty? && primary_key
        #             order(arel_attribute(primary_key).asc)
        #           else
        #             self
        #           end

        relation = self

        if order_values.empty? && primary_key
          if composite?
            relation = relation.order(primary_keys.map { |pk| arel_attribute(pk).asc })
          elsif
            relation = relation.order(arel_attribute(primary_key).asc)
          end
        end

        relation = relation.offset(index) unless index.zero?
        relation.limit(limit).to_a
      end

      def find_one(id)
        # CPK
        # if ActiveRecord::Base === id
        if ::ActiveRecord::Base === id
          id = id.id
          ActiveSupport::Deprecation.warn(<<-MSG.squish)
          You are passing an instance of ActiveRecord::Base to `find`.
          Please pass the id of the object by calling `.id`
          MSG
        end

        # CPK
        #relation = where(primary_key => id)
        relation = where(cpk_id_predicate(table, primary_keys, id))
        record = relation.take

        raise_record_not_found_exception!(id, 0, 1) unless record

        record
      end

      def find_some(ids)
        # CPK
        if composite?
          ids = if ids.length == 1
            ids.first.split(CompositePrimaryKeys::ID_SEP).to_composite_keys
          else
            ids.to_composite_keys
          end
        end

        return find_some_ordered(ids) unless order_values.present?

        # CPK
        # result = where(primary_key => ids).to_a
        result = if composite?
          result = where(cpk_in_predicate(table, primary_keys, ids)).to_a
        else
          result = where(primary_key => ids).to_a
        end

        expected_size =
          if limit_value && ids.size > limit_value
            limit_value
          else
            ids.size
          end

        # 11 ids with limit 3, offset 9 should give 2 results.
        if offset_value && (ids.size - offset_value < expected_size)
          expected_size = ids.size - offset_value
        end

        if result.size == expected_size
          result
        else
          raise_record_not_found_exception!(ids, result.size, expected_size)
        end
      end

      def find_some_ordered(ids)
        ids = ids.slice(offset_value || 0, limit_value || ids.size) || []

        # CPK
        # result = except(:limit, :offset).where(primary_key => ids).records
        result = if composite?
          except(:limit, :offset).where(cpk_in_predicate(table, primary_keys, ids)).records
        else
          except(:limit, :offset).where(primary_key => ids).records
        end

        if result.size == ids.size
          pk_type = @klass.type_for_attribute(primary_key)

          records_by_id = result.index_by(&:id)
          # CPK
          # ids.map { |id| records_by_id.fetch(pk_type.cast(id)) }
          if composite?
            ids.map do |id|
              typecasted_id = primary_keys.zip(id).map do |col, val|
                @klass.type_for_attribute(col).cast(val)
              end
              records_by_id.fetch(typecasted_id)
            end
          else
            ids.map { |id| records_by_id.fetch(pk_type.cast(id)) }
          end
        else
          raise_record_not_found_exception!(ids, result.size, ids.size)
        end
      end
    end
  end
end
