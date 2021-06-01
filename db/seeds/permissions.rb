# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Permission.create_if_not_exists(
  name:        'admin',
  note:        'Admin Interface',
  preferences: {},
)
Permission.create_if_not_exists(
  name:        'admin.user',
  note:        'Manage %s',
  preferences: {
    translations: ['Users']
  },
)
Permission.create_if_not_exists(
  name:        'admin.group',
  note:        'Manage %s',
  preferences: {
    translations: ['Groups']
  },
)
Permission.create_if_not_exists(
  name:        'admin.role',
  note:        'Manage %s',
  preferences: {
    translations: ['Roles']
  },
)
Permission.create_if_not_exists(
  name:        'admin.organization',
  note:        'Manage %s',
  preferences: {
    translations: ['Organizations']
  },
)
Permission.create_if_not_exists(
  name:        'admin.overview',
  note:        'Manage %s',
  preferences: {
    translations: ['Overviews']
  },
)
Permission.create_if_not_exists(
  name:        'admin.text_module',
  note:        'Manage %s',
  preferences: {
    translations: ['Text Modules']
  },
)
Permission.create_if_not_exists(
  name:        'admin.time_accounting',
  note:        'Manage %s',
  preferences: {
    translations: ['Time Accounting']
  },
)
Permission.create_if_not_exists(
  name:        'admin.macro',
  note:        'Manage %s',
  preferences: {
    translations: ['Macros']
  },
)
Permission.create_if_not_exists(
  name:        'admin.tag',
  note:        'Manage %s',
  preferences: {
    translations: ['Tags']
  },
)
Permission.create_if_not_exists(
  name:        'admin.calendar',
  note:        'Manage %s',
  preferences: {
    translations: ['Calendar']
  },
)
Permission.create_if_not_exists(
  name:        'admin.sla',
  note:        'Manage %s',
  preferences: {
    translations: ['SLA']
  },
)
Permission.create_if_not_exists(
  name:        'admin.trigger',
  note:        'Manage %s',
  preferences: {
    translations: ['Triggers']
  },
)
Permission.create_if_not_exists(
  name:        'admin.scheduler',
  note:        'Manage %s',
  preferences: {
    translations: ['Scheduler']
  },
)
Permission.create_if_not_exists(
  name:        'admin.report_profile',
  note:        'Manage %s',
  preferences: {
    translations: ['Report Profiles']
  },
)
Permission.create_if_not_exists(
  name:        'admin.channel_web',
  note:        'Manage %s',
  preferences: {
    translations: ['Channel - Web']
  },
)
Permission.create_if_not_exists(
  name:        'admin.channel_formular',
  note:        'Manage %s',
  preferences: {
    translations: ['Channel - Formular']
  },
)
Permission.create_if_not_exists(
  name:        'admin.channel_email',
  note:        'Manage %s',
  preferences: {
    translations: ['Channel - Email']
  },
)
Permission.create_if_not_exists(
  name:        'admin.channel_twitter',
  note:        'Manage %s',
  preferences: {
    translations: ['Channel - Twitter']
  },
)
Permission.create_if_not_exists(
  name:        'admin.channel_facebook',
  note:        'Manage %s',
  preferences: {
    translations: ['Channel - Facebook']
  },
)
Permission.create_if_not_exists(
  name:        'admin.channel_telegram',
  note:        'Manage %s',
  preferences: {
    translations: ['Channel - Telegram']
  },
)
Permission.create_if_not_exists(
  name:        'admin.channel_google',
  note:        'Manage %s',
  preferences: {
    translations: ['Channel - Google']
  },
)
Permission.create_if_not_exists(
  name:        'admin.channel_microsoft365',
  note:        'Manage %s',
  preferences: {
    translations: ['Channel - Microsoft 365']
  },
)
Permission.create_if_not_exists(
  name:        'admin.channel_sms',
  note:        'Manage %s',
  preferences: {
    translations: ['Channel - SMS']
  },
)
Permission.create_if_not_exists(
  name:        'admin.channel_chat',
  note:        'Manage %s',
  preferences: {
    translations: ['Channel - Chat']
  },
)
Permission.create_if_not_exists(
  name:        'admin.branding',
  note:        'Manage %s',
  preferences: {
    translations: ['Branding']
  },
)
Permission.create_if_not_exists(
  name:        'admin.setting_system',
  note:        'Manage %s Settings',
  preferences: {
    translations: ['System']
  },
)
Permission.create_if_not_exists(
  name:        'admin.security',
  note:        'Manage %s Settings',
  preferences: {
    translations: ['Security']
  },
)
Permission.create_if_not_exists(
  name:        'admin.ticket',
  note:        'Manage %s Settings',
  preferences: {
    translations: ['Ticket']
  },
)
Permission.create_if_not_exists(
  name:        'admin.package',
  note:        'Manage %s',
  preferences: {
    translations: ['Packages']
  },
)
Permission.create_if_not_exists(
  name:        'admin.integration',
  note:        'Manage %s',
  preferences: {
    translations: ['Integrations']
  },
)
Permission.create_if_not_exists(
  name:        'admin.api',
  note:        'Manage %s',
  preferences: {
    translations: ['API']
  },
)
Permission.create_if_not_exists(
  name:        'admin.object',
  note:        'Manage %s',
  preferences: {
    translations: ['Objects']
  },
)
Permission.create_if_not_exists(
  name:        'admin.translation',
  note:        'Manage %s',
  preferences: {
    translations: ['Translations']
  },
)
Permission.create_if_not_exists(
  name:        'admin.monitoring',
  note:        'Manage %s',
  preferences: {
    translations: ['Monitoring']
  },
)
Permission.create_if_not_exists(
  name:        'admin.data_privacy',
  note:        'Manage %s',
  preferences: {
    translations: ['Data Privacy']
  },
)
Permission.create_if_not_exists(
  name:        'admin.maintenance',
  note:        'Manage %s',
  preferences: {
    translations: ['Maintenance']
  },
)
Permission.create_if_not_exists(
  name:        'admin.session',
  note:        'Manage %s',
  preferences: {
    translations: ['Sessions']
  },
)
Permission.create_if_not_exists(
  name:        'admin.webhook',
  note:        'Manage %s',
  preferences: {
    translations: ['Webhooks']
  },
)
Permission.create_if_not_exists(
  name:         'user_preferences',
  note:         'User Preferences',
  preferences:  {},
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.password',
  note:         'Change %s',
  preferences:  {
    translations: ['Password']
  },
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.notifications',
  note:         'Manage %s',
  preferences:  {
    translations: ['Notifications'],
    required:     ['ticket.agent'],
  },
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.access_token',
  note:         'Manage %s',
  preferences:  {
    translations: ['Token Access']
  },
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.language',
  note:         'Change %s',
  preferences:  {
    translations: ['Language']
  },
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.linked_accounts',
  note:         'Manage %s',
  preferences:  {
    translations: ['Linked Accounts']
  },
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.device',
  note:         'Manage %s',
  preferences:  {
    translations: ['Devices']
  },
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.avatar',
  note:         'Manage %s',
  preferences:  {
    translations: ['Avatar']
  },
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.calendar',
  note:         'Access to %s',
  preferences:  {
    translations: ['Calendars'],
    required:     ['ticket.agent'],
  },
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.out_of_office',
  note:         'Change %s',
  preferences:  {
    translations: ['Out of Office'],
    required:     ['ticket.agent'],
  },
  allow_signup: true,
)

Permission.create_if_not_exists(
  name:        'report',
  note:        'Report Interface',
  preferences: {},
)
Permission.create_if_not_exists(
  name:        'ticket',
  note:        'Ticket Interface',
  preferences: {
    disabled: true
  },
)
Permission.create_if_not_exists(
  name:        'ticket.agent',
  note:        'Access to Agent Tickets based on Group Access',
  preferences: {
    plugin: ['groups']
  },
)
Permission.create_if_not_exists(
  name:         'ticket.customer',
  note:         'Access to Customer Tickets based on current_user and organization',
  preferences:  {},
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:        'chat',
  note:        'Access to %s',
  preferences: {
    translations: ['Chat'],
    disabled:     true,
  },
)
Permission.create_if_not_exists(
  name:        'chat.agent',
  note:        'Access to %s',
  preferences: {
    translations: ['Chat'],
  },
)
Permission.create_if_not_exists(
  name:        'cti',
  note:        'CTI',
  preferences: {
    disabled: true
  },
)
Permission.create_if_not_exists(
  name:        'cti.agent',
  note:        'Access to %s',
  preferences: {
    translations: ['CTI'],
  },
)

Permission.create_if_not_exists(
  name:        'admin.knowledge_base',
  note:        'Create and setup %s',
  preferences: {
    translations: ['Knowledge Base']
  }
)

Permission.create_if_not_exists(
  name:        'knowledge_base',
  note:        'Manage %s',
  preferences: {
    translations: ['Knowledge Base'],
    disabled:     true,
  }
)

Permission.create_if_not_exists(
  name:        'knowledge_base.editor',
  note:        'Manage %s',
  preferences: {
    translations: ['Knowledge Base Editor']
  }
)

Permission.create_if_not_exists(
  name:        'knowledge_base.reader',
  note:        'Manage %s',
  preferences: {
    translations: ['Knowledge Base Reader']
  }
)

admin = Role.find_by(name: 'Admin')
admin.permission_grant('user_preferences')
admin.permission_grant('admin')
admin.permission_grant('report')
admin.permission_grant('knowledge_base.editor')

agent = Role.find_by(name: 'Agent')
agent.permission_grant('user_preferences')
agent.permission_grant('ticket.agent')
agent.permission_grant('chat.agent')
agent.permission_grant('cti.agent')
agent.permission_grant('knowledge_base.reader')

customer = Role.find_by(name: 'Customer')
customer.permission_grant('user_preferences.password')
customer.permission_grant('user_preferences.language')
customer.permission_grant('user_preferences.linked_accounts')
customer.permission_grant('user_preferences.avatar')
customer.permission_grant('ticket.customer')
