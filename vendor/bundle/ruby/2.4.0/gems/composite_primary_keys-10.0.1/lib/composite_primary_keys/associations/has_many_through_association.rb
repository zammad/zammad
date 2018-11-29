module ActiveRecord
  module Associations
    class HasManyThroughAssociation
      def cpk_join_through_predicate(*records)
        ensure_mutable

        ids = records.map do |record|
          source_reflection.association_primary_key(reflection.klass).map do |key|
            record.send(key)
          end
        end

        cpk_in_predicate(through_association.scope.klass.arel_table, source_reflection.foreign_key, ids)
      end

      silence_warnings do
        def delete_records(records, method)
          ensure_not_nested

          scope = through_association.scope
          # CPK
          # scope.where! construct_join_attributes(*records)
          if source_reflection.klass.composite?
            scope.where! cpk_join_through_predicate(*records)
          else
            scope.where! construct_join_attributes(*records)
          end

          case method
          when :destroy
            if scope.klass.primary_key
              count = scope.destroy_all.length
            else
              scope.to_a.each do |record|
                record.run_callbacks :destroy
              end

              arel = scope.arel

              stmt = Arel::DeleteManager.new arel.engine
              stmt.from scope.klass.arel_table
              stmt.wheres = arel.constraints

              count = scope.klass.connection.delete(stmt, 'SQL', scope.bind_values)
            end
          when :nullify
            count = scope.update_all(source_reflection.foreign_key => nil)
          else
            count = scope.delete_all
          end

          delete_through_records(records)

          if source_reflection.options[:counter_cache] && method != :destroy
            counter = source_reflection.counter_cache_column
            klass.decrement_counter counter, records.map(&:id)
          end

          if through_reflection.collection? && update_through_counter?(method)
            update_counter(-count, through_reflection)
          end

          update_counter(-count)
        end

        def through_records_for(record)
          # CPK
          # attributes = construct_join_attributes(record)
          # candidates = Array.wrap(through_association.target)
          # candidates.find_all do |c|
          #   attributes.all? do |key, value|
          #     c.public_send(key) == value
          #   end
          # end
          if record.composite?
            candidates = Array.wrap(through_association.target)
            candidates.find_all { |c| c.attributes.slice(*source_reflection.association_primary_key) == record.ids_hash }
          else
            attributes = construct_join_attributes(record)
            candidates = Array.wrap(through_association.target)
            candidates.find_all do |c|
              attributes.all? do |key, value|
                c.public_send(key) == value
              end
            end
          end
        end
      end
    end
  end
end
