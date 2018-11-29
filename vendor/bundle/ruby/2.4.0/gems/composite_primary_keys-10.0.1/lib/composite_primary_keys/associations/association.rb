module ActiveRecord
  module Associations
    class Association
      silence_warnings do
        def creation_attributes
          attributes = {}

          if (reflection.has_one? || reflection.collection?) && !options[:through]
            # CPK
            # attributes[reflection.foreign_key] = owner[reflection.active_record_primary_key]
            Array(reflection.foreign_key).zip(Array(reflection.active_record_primary_key)).each do |key1, key2|
              attributes[key1] = owner[key2]
            end

            if reflection.options[:as]
              attributes[reflection.type] = owner.class.base_class.name
            end
          end

          attributes
        end
      end
    end
  end
end
