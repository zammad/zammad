module ActiveRecord
  module Persistence
    silence_warnings do
      def relation_for_destroy
        # CPK
        if self.composite?
          relation = self.class.unscoped

          Array(self.class.primary_key).each do |key|
            column     = self.class.arel_table[key]
            value      = self[key]
            relation = relation.where(column.eq(value))
          end

          relation
        else
          self.class.unscoped.where(self.class.primary_key => id)
        end
      end

      def touch(*names, time: nil)
        raise ActiveRecordError, "cannot touch on a new record object" unless persisted?

        time ||= current_time_from_proper_timezone
        attributes = timestamp_attributes_for_update_in_model
        attributes.concat(names)

        unless attributes.empty?
          changes = {}

          attributes.each do |column|
            column = column.to_s
            changes[column] = write_attribute(column, time)
          end

          clear_attribute_changes(changes.keys)
          primary_key = self.class.primary_key
          scope = self.class.unscoped.where(primary_key => _read_attribute(primary_key))

          if locking_enabled?
            locking_column = self.class.locking_column
            scope = scope.where(locking_column => _read_attribute(locking_column))
            changes[locking_column] = increment_lock
          end

          # CPK
          if composite?
            primary_key_predicate = self.class.unscoped.cpk_id_predicate(self.class.arel_table, Array(primary_key), Array(id))
            scope = self.class.unscoped.where(primary_key_predicate)
          end

          result = scope.update_all(changes) == 1

          if !result && locking_enabled?
            raise ActiveRecord::StaleObjectError.new(self, "touch")
          end

          result
        else
          true
        end
      end
    end
  end
end