module ActiveRecord
  module Associations
    class Preloader
      class Association
        silence_warnings do
          def records_for(ids)
            # CPK
            # scope.where(association_key_name => ids)

            if reflection.foreign_key.is_a?(Array)
              predicate = cpk_in_predicate(table, reflection.foreign_key, ids)
              scope.where(predicate)
            else
              scope.where(association_key_name => ids)
            end
          end

          def associated_records_by_owner(preloader)
            owners_map = owners_by_key
            # CPK
            # owner_keys = owners_map.keys.compact
            owner_keys = if reflection.foreign_key.is_a?(Array)
              owners.map do |owner|
                Array(owner_key_name).map do |owner_key|
                  owner[owner_key]
                end
              end.compact.uniq
            else
              owners_map.keys.compact
            end

            # Each record may have multiple owners, and vice-versa
            records_by_owner = owners.each_with_object({}) do |owner,h|
              h[owner] = []
            end

            if owner_keys.any?
              # Some databases impose a limit on the number of ids in a list (in Oracle it's 1000)
              # Make several smaller queries if necessary or make one query if the adapter supports it
              sliced  = owner_keys.each_slice(klass.connection.in_clause_length || owner_keys.size)

              records = load_slices sliced
              records.each do |record, owner_key|
                owners_map[owner_key].each do |owner|
                  records_by_owner[owner] << record
                end
              end
            end

            records_by_owner
          end

          def load_slices(slices)
            @preloaded_records = slices.flat_map { |slice|
              records_for(slice)
            }

            # CPK
            # @preloaded_records.map { |record|
            #   key = record[association_key_name]
            #   key = key.to_s if key_conversion_required?
            #
            #   [record, key]
            # }
            @preloaded_records.map { |record|
              key = Array(association_key_name).map do |key_name|
                record[key_name]
              end.join(CompositePrimaryKeys::ID_SEP)

              [record, key]
            }
          end

          def owners_by_key
            @owners_by_key ||= if key_conversion_required?
                                 owners.group_by do |owner|
                                   # CPK
                                   # owner[owner_key_name].to_s
                                   Array(owner_key_name).map do |key_name|
                                     owner[key_name]
                                   end.join(CompositePrimaryKeys::ID_SEP)
                                 end
                               else
                                 owners.group_by do |owner|
                                   # CPK
                                   # owner[owner_key_name]
                                   Array(owner_key_name).map do |key_name|
                                     owner[key_name]
                                   end.join(CompositePrimaryKeys::ID_SEP)
                                 end
                               end

          end
        end
      end
    end
  end
end
