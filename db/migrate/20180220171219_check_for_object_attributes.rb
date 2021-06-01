# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CheckForObjectAttributes < ActiveRecord::Migration[5.1]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    attributes.each do |attribute|

      fix_nil_data_option(attribute)
      fix_options(attribute)
      fix_relation(attribute)
      fix_interger_missing_min_max(attribute)

      next if !attribute.changed?

      attribute.save!
    end
  end

  private

  def attributes
    ObjectManager::Attribute.all
  end

  def fix_nil_data_option(attribute)
    return if attribute[:data_option].is_a?(Hash) || attribute[:data_option][:options].is_a?(Array)

    attribute[:data_option] = {}
  end

  def fix_options(attribute)
    return if attribute[:data_option][:options].is_a?(Hash)
    return if attribute[:data_option][:options].is_a?(Array)

    attribute[:data_option][:options] = {}
  end

  def fix_relation(attribute)
    return if attribute[:data_option][:relation].is_a?(String)

    attribute[:data_option][:relation] = ''
  end

  # fixes issue #2318 - Upgrade to Zammad 2.7 was not possible (migration 20180220171219 CheckForObjectAttributes failed)
  def fix_interger_missing_min_max(attribute)
    return if attribute[:data_type] != 'integer'

    attribute[:data_option][:min] = 0 if !attribute[:data_option][:min]
    attribute[:data_option][:max] = 1_000_000 if !attribute[:data_option][:max]
  end
end
