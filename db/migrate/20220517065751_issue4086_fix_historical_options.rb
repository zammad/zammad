# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4086FixHistoricalOptions < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute.find_each do |attribute|
      next if !%r{^(multi|tree_)?select$}.match?(attribute.data_type)

      attribute.data_option[:historical_options] = ObjectManager::Attribute.data_options_hash(attribute.data_option[:historical_options] || {})
      attribute.save
    end
  end
end
