# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class PermissionSettingWording < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    update_permissions
    update_settings
  end

  PERMISSIONS_TO_UPDATE = [
    {
      name: 'knowledge_base',
      note: 'Knowledge Base',
    },
    {
      name: 'knowledge_base.editor',
      note: 'Knowledge Base Editor',
    },
    {
      name: 'knowledge_base.reader',
      note: 'Knowledge Base Reader',
    },
    {
      name: 'ticket.customer',
      note: 'Access to customer tickets'
    }
  ].freeze

  def update_permissions
    PERMISSIONS_TO_UPDATE.each do |perm_def|
      Permission.find_by(name: perm_def[:name])&.tap do |perm|
        perm.note = perm_def[:note]
        perm.preferences.delete('translations')
        perm.save!
      end
    end
  end

  SETTINGS_TO_UPDATE = [
    {
      title: 'Maximum Recursive Ticket Triggers Depth',
      name:  'ticket_trigger_recursive_max_loop',
    },
    {
      title:       'Enforce the setup of the two-factor authentication',
      name:        'two_factor_authentication_enforce_role_ids',
      description: 'Requires the setup of the two-factor authentication for certain user roles.',
    },
    {
      title:       'Additional notes for ticket create types.',
      name:        'ui_ticket_create_notes',
      description: 'Show additional notes for ticket creation depending on the selected type.',
    },
    {
      title: 'Storage Method',
      name:  'storage_provider',
    }
  ].freeze

  def update_settings
    SETTINGS_TO_UPDATE.each do |setting_def|
      Setting.find_by(name: setting_def[:name])&.tap do |setting|
        setting.title = setting_def[:title]
        setting.description = setting_def[:description] if setting_def[:description]
        setting.save!
      end
    end

  end
end
