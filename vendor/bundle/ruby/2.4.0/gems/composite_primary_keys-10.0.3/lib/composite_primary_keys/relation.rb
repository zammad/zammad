module ActiveRecord
  class Relation
    alias :initialize_without_cpk :initialize
    def initialize(klass, table, predicate_builder, values = {})
      initialize_without_cpk(klass, table, predicate_builder, values)
      add_cpk_support if klass && klass.composite?
    end

    alias :initialize_copy_without_cpk :initialize_copy
    def initialize_copy(other)
      initialize_copy_without_cpk(other)
      add_cpk_support if klass.composite?
    end

    def add_cpk_support
      extend CompositePrimaryKeys::CompositeRelation
    end

    silence_warnings do
      def _update_record(values, id, id_was) # :nodoc:
        substitutes, binds = substitute_values values

        scope = @klass.unscoped

        if @klass.finder_needs_type_condition?
          scope.unscope!(where: @klass.inheritance_column)
        end

        # CPK
        if self.composite?
          relation = @klass.unscoped.where(cpk_id_predicate(@klass.arel_table, @klass.primary_key, id_was || id))
        else
          relation = scope.where(@klass.primary_key => (id_was || id))
        end


        bvs = binds + relation.bound_attributes
        um = relation
          .arel
          .compile_update(substitutes, @klass.primary_key)

        @klass.connection.update(
          um,
          'SQL',
          bvs,
        )
      end
    end

    def update_all(updates)
      raise ArgumentError, "Empty list of attributes to change" if updates.blank?

      stmt = Arel::UpdateManager.new

      stmt.set Arel.sql(@klass.send(:sanitize_sql_for_assignment, updates))
      stmt.table(table)

      if joins_values.any?
        # CPK
        #@klass.connection.join_to_update(stmt, arel, arel_attribute(primary_key))
        if primary_key.kind_of?(Array)
          attributes = primary_key.map do |key|
            arel_attribute(key)
          end
          @klass.connection.join_to_update(stmt, arel, attributes.to_composite_keys)
        else
          @klass.connection.join_to_update(stmt, arel, arel_attribute(primary_key))
        end
      else
        stmt.key = arel_attribute(primary_key)
        stmt.take(arel.limit)
        stmt.order(*arel.orders)
        stmt.wheres = arel.constraints
      end

      @klass.connection.update stmt, 'SQL', bound_attributes
    end


    def delete_all(conditions = nil)
      invalid_methods = INVALID_METHODS_FOR_DELETE_ALL.select { |method|
        if MULTI_VALUE_METHODS.include?(method)
          send("#{method}_values").any?
        elsif SINGLE_VALUE_METHODS.include?(method)
          send("#{method}_value")
        elsif CLAUSE_METHODS.include?(method)
          send("#{method}_clause").any?
        end
      }
      if invalid_methods.any?
        raise ActiveRecordError.new("delete_all doesn't support #{invalid_methods.join(', ')}")
      end

      if conditions
        ActiveSupport::Deprecation.warn(<<-MESSAGE.squish)
          Passing conditions to delete_all is deprecated and will be removed in Rails 5.1.
          To achieve the same use where(conditions).delete_all.
        MESSAGE
        where(conditions).delete_all
      else
        stmt = Arel::DeleteManager.new
        stmt.from(table)

        # CPK
        if joins_values.any? && @klass.composite?
          arel_attributes = Array(primary_key).map do |key|
            arel_attribute(key)
          end.to_composite_keys
          @klass.connection.join_to_delete(stmt, arel, arel_attributes)
        elsif joins_values.any?
          @klass.connection.join_to_delete(stmt, arel, arel_attribute(primary_key))
        else
          stmt.wheres = arel.constraints
        end

        affected = @klass.connection.delete(stmt, 'SQL', bound_attributes)

        reset
        affected
      end
    end
  end
end
