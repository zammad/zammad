# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class MultiTreeSelectAddHistoricalOptions < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_historical_options_to_multi_tree_select_attributes
  end

  private

  def add_historical_options_to_multi_tree_select_attributes
    ObjectManager::Attribute.where(data_type: 'multi_tree_select').find_each do |attribute|
      next if attribute.data_option[:historical_options].present?
      next if attribute.data_option[:options].blank?

      attribute.data_option[:historical_options] = ObjectManager::Attribute.attribute_historic_options(attribute)
      attribute.save!(validate: false)
    end
  end
end
