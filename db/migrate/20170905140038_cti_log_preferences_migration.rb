# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Rails dropped the class
# ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter::MysqlDateTime
# via: https://github.com/rails/rails/commit/f1a0fa9e19b7e4ccaea191fc6cf0613880222ee7
# ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Integer
# via: https://github.com/rails/rails/commit/aafee233fb3b4211ee0bfb1fca776c159bd1067e
# which we use in stored Cti::Log instance preferences.
# Since we don't need the instances but just an Hash we have to:
# - create a dummy class
# - loop over all instances
# - deserialize them in the preferences
# - replace them in the preferences with the Hash version

# create a dummy class
module ActiveRecord
  module ConnectionAdapters
    class AbstractMysqlAdapter
      class MysqlDateTime < Type::DateTime
      end
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module OID
        class Integer < Type::Integer
        end
      end
    end
  end
end

class CtiLogPreferencesMigration < ActiveRecord::Migration[5.0]

  def change

    # correct all entries
    directions = %w[from to]
    Cti::Log.all.pluck(:id).each do |item_id|
      item = Cti::Log.find(item_id)
      next if !item.preferences
      next if item.preferences.blank?

      # check from and to keys which hold the instances
      preferences = {}
      directions.each do |direction|
        next if item.preferences[direction].blank?

        # loop over all instances and covert them
        # to an Hash via .attributes
        updated = item.preferences[direction].each_with_object([]) do |caller_id, new_direction|
          next if !caller_id.respond_to?(:attributes)

          new_direction.push(caller_id.attributes)
        end

        # overwrite the old key with the converted data
        preferences[direction] = updated
      end

      # update entry
      item.update_column(:preferences, preferences) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
