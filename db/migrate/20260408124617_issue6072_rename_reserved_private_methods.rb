# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue6072RenameReservedPrivateMethods < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    %w[execute execute_before_save prepare_actions notification_action ai_action additional_object_action object_action attribute_update_action create_action_instance].each do |method|
      MigrationHelper.rename_custom_object_attribute_reserved(method, models: %w[Ticket User Organization])
    end
  end
end
