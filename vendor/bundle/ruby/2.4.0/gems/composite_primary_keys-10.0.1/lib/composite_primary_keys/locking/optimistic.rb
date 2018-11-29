module ActiveRecord
  module Locking
    module Optimistic

      private

      silence_warnings do
        def _update_record(attribute_names = @attributes.keys) #:nodoc:
          return super unless locking_enabled?
          return 0 if attribute_names.empty?

          lock_col = self.class.locking_column
          previous_lock_value = send(lock_col).to_i
          increment_lock

          attribute_names += [lock_col]
          attribute_names.uniq!

          begin
            relation = self.class.unscoped

            if self.composite?
              affected_rows = relation.where(
                  relation.cpk_id_predicate(relation.table, self.class.primary_key, id_was)
              ).where(
                  lock_col => previous_lock_value
              ).update_all(
                  Hash[attributes_for_update(attribute_names).map do |name|
                         [name, _read_attribute(name)]
                       end]
              )
            else
              affected_rows = relation.where(
                  self.class.primary_key => id,
                  lock_col => previous_lock_value,
              ).update_all(
                  Hash[attributes_for_update(attribute_names).map do |name|
                       [name, _read_attribute(name)]
                     end]
              )
            end

            unless affected_rows == 1
              raise ActiveRecord::StaleObjectError.new(self, "update")
            end

            affected_rows

          # If something went wrong, revert the version.
          rescue Exception
            send(lock_col + '=', previous_lock_value)
            raise
          end
        end
      end
    end
  end
end
