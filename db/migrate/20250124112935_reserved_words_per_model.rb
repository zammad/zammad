# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ReservedWordsPerModel < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    reserved_name = 'article'
    sanitized_name = '_article'

    # Rename column in database.
    if ActiveRecord::Base.connection.columns(Ticket.table_name).map(&:name).include?(reserved_name)
      ActiveRecord::Migration.rename_column(:tickets, reserved_name.to_sym, sanitized_name.to_sym)
      Ticket.reset_column_information
    end

    # Rename the attribute itself.
    attribute = ObjectManager::Attribute.get(
      object: Ticket.to_app_model,
      name:   reserved_name,
    )
    return if !attribute

    attribute.update!(name: sanitized_name)
  end
end
