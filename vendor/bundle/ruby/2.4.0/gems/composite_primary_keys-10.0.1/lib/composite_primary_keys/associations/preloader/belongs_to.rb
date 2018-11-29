module ActiveRecord
  module Associations
    class Preloader
      class BelongsTo
        def records_for(ids)
          # CPK
          # scope.where(association_key.in(ids))

          if association_key_name.is_a?(Array)
            predicate = cpk_in_predicate(table, association_key_name, ids)
            scope.where(predicate)
          else
            scope.where(association_key_name => ids)
          end
        end
      end
    end
  end
end
