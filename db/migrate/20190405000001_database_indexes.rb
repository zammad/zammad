# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class DatabaseIndexes < ActiveRecord::Migration[5.1]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    map = {
      activity_streams: [
        {
          columns: %i[permission_id group_id],
        },
        {
          columns: %i[permission_id group_id created_at],
          name:    'index_activity_streams_on_permission_id_group_id_created_at',
        },
      ],
      stores:           [
        {
          columns: [:store_file_id],
        },
      ],
      cti_caller_ids:   [
        {
          columns: %i[object o_id level user_id caller_id],
          name:    'index_cti_caller_ids_on_object_o_id_level_user_id_caller_id',
        },
      ],
      tickets:          [
        {
          columns: [:updated_at],
        },
        {
          columns: %i[customer_id state_id created_at],
        },
        {
          columns: %i[group_id state_id updated_at],
        },
        {
          columns: %i[group_id state_id owner_id updated_at],
          name:    'index_tickets_on_group_id_state_id_owner_id_updated_at',
        },
        {
          columns: %i[group_id state_id created_at],
        },
        {
          columns: %i[group_id state_id owner_id created_at],
          name:    'index_tickets_on_group_id_state_id_owner_id_created_at',
        },
        {
          columns: %i[group_id state_id close_at],
        },
        {
          columns: %i[group_id state_id owner_id close_at],
          name:    'index_tickets_on_group_id_state_id_owner_id_close_at',
        },
      ]
    }

    map.each do |table, indexes|
      indexes.each do |index|

        params = [table, index[:columns]]
        params.push(name: index[:name]) if index[:name]

        next if index_exists?(*params)

        add_index(*params)
      end
    end

  end
end
