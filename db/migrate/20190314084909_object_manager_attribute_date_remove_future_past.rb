# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ObjectManagerAttributeDateRemoveFuturePast < ActiveRecord::Migration[5.1]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute.where(data_type: 'date').each do |attribute|
      attribute.data_option = attribute.data_option.except(:future, :past)

      # some attributes from the early Zammad days don't have all
      # required data_option attributes because they were not properly migrated
      # so we need to fix them now
      attribute.data_option[:diff] ||= 24

      attribute.save!
    end
  end
end
