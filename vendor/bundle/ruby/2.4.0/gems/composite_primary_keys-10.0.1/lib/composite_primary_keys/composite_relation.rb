module CompositePrimaryKeys
  module CompositeRelation
    include CompositePrimaryKeys::ActiveRecord::Batches
    include CompositePrimaryKeys::ActiveRecord::Calculations
    include CompositePrimaryKeys::ActiveRecord::FinderMethods
    include CompositePrimaryKeys::ActiveRecord::QueryMethods

    def delete(id_or_array)
      # CPK
      if self.composite?
        id_or_array = if id_or_array.is_a?(CompositePrimaryKeys::CompositeKeys)
                        [id_or_array]
                      else
                        Array(id_or_array)
                      end

        id_or_array.each do |id|
          # Is the passed in id actually a record?
          id = id.kind_of?(::ActiveRecord::Base) ? id.id : id
          where(cpk_id_predicate(table, self.primary_key, id)).delete_all
        end
      else
        where(primary_key => id_or_array).delete_all
      end
    end

    def destroy(id_or_array)
      # Without CPK:
      #if id.is_a?(Array)
      #  id.map { |one_id| destroy(one_id) }
      #else
      #  find(id).destroy
      #end

      id_or_array = if id_or_array.kind_of?(CompositePrimaryKeys::CompositeKeys)
        [id_or_array]
      else
        Array(id_or_array)
      end

      id_or_array.each do |id|
        where(cpk_id_predicate(table, self.primary_key, id)).each do |record|
          record.destroy
        end
      end
    end
  end
end
