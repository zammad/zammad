# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Permission.create_if_not_exists(
  name:        'admin',
  note:        __('Admin Interface'),
  preferences: {},
)
Permission.create_if_not_exists(
  name:        'admin.user',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Users')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.group',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Groups')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.role',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Roles')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.organization',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Organizations')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.overview',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Overviews')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.text_module',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Text Modules')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.time_accounting',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Time Accounting')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.macro',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Macros')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.tag',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Tags')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.calendar',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Calendar')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.sla',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('SLA')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.trigger',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Triggers')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.scheduler',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Scheduler')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.report_profile',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Report Profiles')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.channel_web',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Channel - Web')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.channel_formular',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Channel - Form')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.channel_email',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Channel - Email')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.channel_twitter',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Channel - Twitter')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.channel_facebook',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Channel - Facebook')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.channel_telegram',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Channel - Telegram')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.channel_google',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Channel - Google')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.channel_microsoft365',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Channel - Microsoft 365')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.channel_sms',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Channel - SMS')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.channel_chat',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Channel - Chat')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.branding',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Branding')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.setting_system',
  note:        __('Manage %s Settings'),
  preferences: {
    translations: [__('System')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.security',
  note:        __('Manage %s Settings'),
  preferences: {
    translations: [__('Security')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.ticket',
  note:        __('Manage %s Settings'),
  preferences: {
    translations: [__('Ticket')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.package',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Packages')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.integration',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Integrations')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.api',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('API')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.object',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Objects')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.template',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Templates')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.translation',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Translations')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.monitoring',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Monitoring')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.data_privacy',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Data Privacy')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.maintenance',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Maintenance')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.session',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Sessions')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.webhook',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Webhooks')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.core_workflow',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Core Workflow')]
  },
)
Permission.create_if_not_exists(
  name:        'admin.public_links',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Public Links')]
  },
)
Permission.create_if_not_exists(
  name:         'user_preferences',
  note:         __('User Preferences'),
  preferences:  {},
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.password',
  note:         __('Change %s'),
  preferences:  {
    translations: [__('Password')]
  },
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.notifications',
  note:         __('Manage %s'),
  preferences:  {
    translations: [__('Notifications')],
    required:     ['ticket.agent'],
  },
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.access_token',
  note:         __('Manage %s'),
  preferences:  {
    translations: [__('Token Access')]
  },
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.language',
  note:         __('Change %s'),
  preferences:  {
    translations: [__('Language')]
  },
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.linked_accounts',
  note:         __('Manage %s'),
  preferences:  {
    translations: [__('Linked Accounts')]
  },
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.device',
  note:         __('Manage %s'),
  preferences:  {
    translations: [__('Devices')]
  },
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.avatar',
  note:         __('Manage %s'),
  preferences:  {
    translations: [__('Avatar')]
  },
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.calendar',
  note:         __('Access to %s'),
  preferences:  {
    translations: [__('Calendars')],
    required:     ['ticket.agent'],
  },
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.out_of_office',
  note:         __('Change %s'),
  preferences:  {
    translations: [__('Out of Office')],
    required:     ['ticket.agent'],
  },
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.overview_sorting',
  note:         __('Change %s'),
  preferences:  {
    translations: [__('Order of Overviews')],
    required:     ['ticket.agent'],
  },
  allow_signup: true,
)

Permission.create_if_not_exists(
  name:         'user_preferences.appearance',
  note:         __('Manage %s'),
  preferences:  {
    translations: [__('Appearance')]
  },
  allow_signup: true,
)

Permission.create_if_not_exists(
  name:        'report',
  note:        __('Report Interface'),
  preferences: {},
)
Permission.create_if_not_exists(
  name:        'ticket',
  note:        __('Ticket Interface'),
  preferences: {
    disabled: true
  },
)
Permission.create_if_not_exists(
  name:        'ticket.agent',
  note:        __('Access to Agent Tickets based on Group Access'),
  preferences: {
    plugin: ['groups']
  },
)
Permission.create_if_not_exists(
  name:         'ticket.customer',
  note:         __('Access to Customer Tickets based on current_user and organization'),
  preferences:  {},
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:        'chat',
  note:        __('Access to %s'),
  preferences: {
    translations: [__('Chat')],
    disabled:     true,
  },
)
Permission.create_if_not_exists(
  name:        'chat.agent',
  note:        __('Access to %s'),
  preferences: {
    translations: [__('Chat')],
  },
)
Permission.create_if_not_exists(
  name:        'cti',
  note:        __('CTI'),
  preferences: {
    disabled: true
  },
)
Permission.create_if_not_exists(
  name:        'cti.agent',
  note:        __('Access to %s'),
  preferences: {
    translations: [__('CTI')],
  },
)

Permission.create_if_not_exists(
  name:        'admin.knowledge_base',
  note:        __('Create and set up %s'),
  preferences: {
    translations: [__('Knowledge Base')]
  }
)

Permission.create_if_not_exists(
  name:        'knowledge_base',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Knowledge Base')],
    disabled:     true,
  }
)

Permission.create_if_not_exists(
  name:        'knowledge_base.editor',
  note:        __('Manage %s'),
  preferences: {
    translations: [__('Knowledge Base Editor')]
  }
)

Permission.create_if_not_exists(
  name:         'knowledge_base.reader',
  note:         __('Manage %s'),
  preferences:  {
    translations: [__('Knowledge Base Reader')]
  },
  allow_signup: true,
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
customer.permission_grant('user_preferences.appearance')
customer.permission_grant('ticket.customer')
