# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class StatsStorePolymorphicAssociation < ActiveRecord::Migration[5.2]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    # create ObjectLookup ID -> Model map
    object_lookup_map = ObjectLookup.all.pluck(:id, :name)

    # create empty, indexed polymorphic association columns
    add_reference :stats_stores, :stats_storable, polymorphic: true, index: true

    # set last run 20 min in future to avoid scheduler errors until restart
    Scheduler.find_by(method: 'Stats.generate').update(last_run: 20.minutes.from_now)

    # migrate column data in the most performance way
    object_lookup_map.each do |id, model|
      StatsStore.where(stats_store_object_id: id)
                .update_all("stats_storable_id = o_id, stats_storable_type = '#{model}'") # rubocop:disable Rails/SkipsModelValidations
    end

    remove_unneeded_columns
  end

  private

  def remove_unneeded_columns
    # remove home made "polymorphic association" columns
    remove_column :stats_stores, :o_id
    remove_column :stats_stores, :stats_store_object_id

    # remove unused/obsolete columns
    remove_column :stats_stores, :related_stats_store_object_id
    remove_column(:stats_stores, :related_o_id) if StatsStore.column_names.include?('related_o_id')
  end
end
