class AddPermission < ActiveRecord::Migration
  def change

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    create_table :permissions do |t|
      t.string :name, limit: 255, null: false
      t.string :note, limit: 500, null: true
      t.string :preferences, limit: 10_000, null: true
      t.timestamps limit: 3, null: false
    end
    add_index :permissions, [:name], unique: true

    create_table :permissions_roles, id: false do |t|
      t.belongs_to :role, index: true
      t.belongs_to :permission, index: true
    end

    Permission.create_or_update(
      name: 'admin',
      note: 'Admin Interface',
      preferences: {},
    )
    Permission.create_or_update(
      name: 'admin.user',
      note: 'Manage %s',
      preferences: {
        translations: ['Users']
      },
    )
    Permission.create_or_update(
      name: 'admin.group',
      note: 'Manage %s',
      preferences: {
        translations: ['Groups']
      },
    )
    Permission.create_or_update(
      name: 'admin.role',
      note: 'Manage %s',
      preferences: {
        translations: ['Roles']
      },
    )
    Permission.create_or_update(
      name: 'admin.organization',
      note: 'Manage %s',
      preferences: {
        translations: ['Organizations']
      },
    )
    Permission.create_or_update(
      name: 'admin.overview',
      note: 'Manage %s',
      preferences: {
        translations: ['Overviews']
      },
    )
    Permission.create_or_update(
      name: 'admin.text_module',
      note: 'Manage %s',
      preferences: {
        translations: ['Text Modules']
      },
    )
    Permission.create_or_update(
      name: 'admin.macro',
      note: 'Manage %s',
      preferences: {
        translations: ['Macros']
      },
    )
    Permission.create_or_update(
      name: 'admin.tag',
      note: 'Manage %s',
      preferences: {
        translations: ['Tags']
      },
    )
    Permission.create_or_update(
      name: 'admin.calendar',
      note: 'Manage %s',
      preferences: {
        translations: ['Calendar']
      },
    )
    Permission.create_or_update(
      name: 'admin.sla',
      note: 'Manage %s',
      preferences: {
        translations: ['SLA']
      },
    )
    Permission.create_or_update(
      name: 'admin.scheduler',
      note: 'Manage %s',
      preferences: {
        translations: ['Scheduler']
      },
    )
    Permission.create_or_update(
      name: 'admin.report_profile',
      note: 'Manage %s',
      preferences: {
        translations: ['Report Profiles']
      },
    )
    Permission.create_or_update(
      name: 'admin.channel_web',
      note: 'Manage %s',
      preferences: {
        translations: ['Channel - Web']
      },
    )
    Permission.create_or_update(
      name: 'admin.channel_formular',
      note: 'Manage %s',
      preferences: {
        translations: ['Channel - Formular']
      },
    )
    Permission.create_or_update(
      name: 'admin.channel_web',
      note: 'Manage %s',
      preferences: {
        translations: ['Channel - Web']
      },
    )
    Permission.create_or_update(
      name: 'admin.channel_email',
      note: 'Manage %s',
      preferences: {
        translations: ['Channel - Email']
      },
    )
    Permission.create_or_update(
      name: 'admin.channel_twitter',
      note: 'Manage %s',
      preferences: {
        translations: ['Channel - Twitter']
      },
    )
    Permission.create_or_update(
      name: 'admin.channel_facebook',
      note: 'Manage %s',
      preferences: {
        translations: ['Channel - Facebook']
      },
    )
    Permission.create_or_update(
      name: 'admin.channel_chat',
      note: 'Manage %s',
      preferences: {
        translations: ['Channel - Chat']
      },
    )
    Permission.create_or_update(
      name: 'admin.branding',
      note: 'Manage %s',
      preferences: {
        translations: ['Branding']
      },
    )
    Permission.create_or_update(
      name: 'admin.setting_system',
      note: 'Manage %s Settings',
      preferences: {
        translations: ['System']
      },
    )
    Permission.create_or_update(
      name: 'admin.security',
      note: 'Manage %s Settings',
      preferences: {
        translations: ['Security']
      },
    )
    Permission.create_or_update(
      name: 'admin.ticket',
      note: 'Manage %s Settings',
      preferences: {
        translations: ['Ticket']
      },
    )
    Permission.create_or_update(
      name: 'admin.package',
      note: 'Manage %s',
      preferences: {
        translations: ['Packages']
      },
    )
    Permission.create_or_update(
      name: 'admin.integration',
      note: 'Manage %s',
      preferences: {
        translations: ['Integrations']
      },
    )
    Permission.create_or_update(
      name: 'admin.api',
      note: 'Manage %s',
      preferences: {
        translations: ['API']
      },
    )
    Permission.create_or_update(
      name: 'admin.object',
      note: 'Manage %s',
      preferences: {
        translations: ['Objects']
      },
    )
    Permission.create_or_update(
      name: 'admin.translation',
      note: 'Manage %s',
      preferences: {
        translations: ['Translations']
      },
    )
    Permission.create_or_update(
      name: 'admin.maintenance',
      note: 'Manage %s',
      preferences: {
        translations: ['Maintenance']
      },
    )
    Permission.create_or_update(
      name: 'admin.session',
      note: 'Manage %s',
      preferences: {
        translations: ['Sessions']
      },
    )
    Permission.create_or_update(
      name: 'user_preferences',
      note: 'User Preferences',
      preferences: {},
    )
    Permission.create_or_update(
      name: 'user_preferences.password',
      note: 'Change %s',
      preferences: {
        translations: ['Password']
      },
    )
    Permission.create_or_update(
      name: 'user_preferences.notifications',
      note: 'Manage %s',
      preferences: {
        translations: ['Notifications'],
        required: ['ticket.agent'],
      },
    )
    Permission.create_or_update(
      name: 'user_preferences.access_token',
      note: 'Manage %s',
      preferences: {
        translations: ['Token Access']
      },
    )
    Permission.create_or_update(
      name: 'user_preferences.language',
      note: 'Change %s',
      preferences: {
        translations: ['Language']
      },
    )
    Permission.create_or_update(
      name: 'user_preferences.linked_accounts',
      note: 'Manage %s',
      preferences: {
        translations: ['Linked Accounts']
      },
    )
    Permission.create_or_update(
      name: 'user_preferences.device',
      note: 'Manage %s',
      preferences: {
        translations: ['Devices']
      },
    )
    Permission.create_or_update(
      name: 'user_preferences.avatar',
      note: 'Manage %s',
      preferences: {
        translations: ['Avatar']
      },
    )
    Permission.create_or_update(
      name: 'user_preferences.calendar',
      note: 'Access to %s',
      preferences: {
        translations: ['Calendars'],
        required: ['ticket.agent'],
      },
    )

    Permission.create_or_update(
      name: 'report',
      note: 'Report Interface',
      preferences: {},
    )
    Permission.create_or_update(
      name: 'ticket',
      note: 'Ticket Interface',
      preferences: {
        disabled: true
      },
    )
    Permission.create_or_update(
      name: 'ticket.agent',
      note: 'Access to Agent Tickets based on Group Access',
      preferences: {
        not: ['ticket.customer'],
        plugin: ['groups']
      },
    )
    Permission.create_or_update(
      name: 'ticket.customer',
      note: 'Access to Customer Tickets based on current_user and current_user.organization',
      preferences: {
        not: ['ticket.agent'],
      },
    )
    Permission.create_or_update(
      name: 'chat',
      note: 'Access to %s',
      preferences: {
        disabled: true,
        translations: ['Chat']
      },
    )
    Permission.create_or_update(
      name: 'chat.agent',
      note: 'Access to %s',
      preferences: {
        translations: ['Chat'],
        not: ['chat.customer'],
      },
    )
    Permission.create_or_update(
      name: 'cti',
      note: 'CTI',
      preferences: {
        disabled: true
      },
    )
    Permission.create_or_update(
      name: 'cti.agent',
      note: 'Access to %s',
      preferences: {
        translations: ['CTI'],
        not: ['cti.customer'],
      },
    )

    admin = Role.find_by(name: 'Admin')
    admin.permission_grand('user_preferences')
    admin.permission_grand('admin')
    admin.permission_grand('report')

    agent = Role.find_by(name: 'Agent')
    agent.permission_grand('user_preferences')
    agent.permission_grand('ticket.agent')
    agent.permission_grand('chat.agent')
    agent.permission_grand('cti.agent')

    customer = Role.find_by(name: 'Customer')
    customer.permission_grand('user_preferences.password')
    customer.permission_grand('user_preferences.language')
    customer.permission_grand('user_preferences.linked_accounts')
    customer.permission_grand('user_preferences.avatar')
    customer.permission_grand('ticket.customer')

  end
end
