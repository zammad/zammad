# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue3123ExternalSyncTicketMerge < ActiveRecord::Migration[5.2]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    merged_ticket_ids_with_external_sync.each do |id_from|
      id_to = merged_ticket_ids_map[id_from]
      ExternalSync.migrate('Ticket', id_from, id_to)
    end
  end

  private

  # reduce to the ones with an ExternalSync entry
  def merged_ticket_ids_with_external_sync
    @merged_ticket_ids_with_external_sync ||= ExternalSync.where(
      object: 'Ticket',
      o_id:   merged_ticket_ids_map.keys,
    ).pluck(:o_id).uniq
  end

  # get all merged tickets
  def merged_ticket_ids_map
    @merged_ticket_ids_map ||= History.where(
      history_type_id:   History.type_lookup('merged_into').id,
      history_object_id: History.object_lookup('Ticket').id,
    ).pluck(:id_from, :id_to).to_h
  end

end
