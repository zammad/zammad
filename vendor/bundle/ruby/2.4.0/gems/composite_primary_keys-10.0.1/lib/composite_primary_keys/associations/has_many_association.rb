module ActiveRecord
  module Associations
    class HasManyAssociation
      include CompositePrimaryKeys::Predicates

      def delete_records(records, method)
        if method == :destroy
          records.each(&:destroy!)
          update_counter(-records.length) unless reflection.inverse_updates_counter_cache?
          return
        # Zerista
        elsif self.reflection.klass.composite?
          predicate = cpk_in_predicate(self.scope.table, self.reflection.klass.primary_keys, records.map(&:id))
          scope = self.scope.where(predicate)
        else
          scope = self.scope.where(reflection.klass.primary_key => records)
        end
        update_counter(-delete_count(method, scope))
      end

      def delete_count(method, scope)
        if method == :delete_all
          scope.delete_all
        else
          # CPK
          # scope.update_all(reflection.foreign_key => nil)
          conds = Array(reflection.foreign_key).inject(Hash.new) do |mem, key|
            mem[key] = nil
            mem
          end
          scope.update_all(conds)
        end
      end

      def foreign_key_present?
        if reflection.klass.primary_key
          # CPK
          # owner.attribute_present?(reflection.association_primary_key)
          Array(reflection.klass.primary_key).all? {|key| owner.attribute_present?(key)}
        else
          false
        end
      end
    end
  end
end
