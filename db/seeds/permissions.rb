# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

Permission.create_if_not_exists(
  name:        'admin',
  label:       __('Admin interface'),
  description: __('Configure your system.'),
  preferences: { prio: 1000 }
)
Permission.create_if_not_exists(
  name:        'admin.user',
  label:       __('Users'),
  description: __('Manage all users of your system.'),
  preferences: { prio: 1010 }
)
Permission.create_if_not_exists(
  name:        'admin.group',
  label:       __('Groups'),
  description: __('Manage groups of your system.'),
  preferences: { prio: 1020 }
)
Permission.create_if_not_exists(
  name:        'admin.role',
  label:       __('Roles'),
  description: __('Manage roles of your system.'),
  preferences: { prio: 1030 }
)
Permission.create_if_not_exists(
  name:        'admin.organization',
  label:       __('Organizations'),
  description: __('Manage all organizations of your system.'),
  preferences: { prio: 1040 }
)
Permission.create_if_not_exists(
  name:        'admin.overview',
  label:       __('Overviews'),
  description: __('Manage ticket overviews of your system.'),
  preferences: { prio: 1050 }
)
Permission.create_if_not_exists(
  name:        'admin.text_module',
  label:       __('Text modules'),
  description: __('Manage text modules of your system.'),
  preferences: { prio: 1060 }
)
Permission.create_if_not_exists(
  name:        'admin.macro',
  label:       __('Macros'),
  description: __('Manage ticket macros of your system.'),
  preferences: { prio: 1070 }
)
Permission.create_if_not_exists(
  name:        'admin.template',
  label:       __('Templates'),
  description: __('Manage ticket templates of your system.'),
  preferences: { prio: 1080 }
)
Permission.create_if_not_exists(
  name:        'admin.tag',
  label:       __('Tags'),
  description: __('Manage ticket tags of your system.'),
  preferences: { prio: 1090 }
)
Permission.create_if_not_exists(
  name:        'admin.calendar',
  label:       __('Calendars'),
  description: __('Manage calendars of your system.'),
  preferences: { prio: 1100 }
)
Permission.create_if_not_exists(
  name:        'admin.sla',
  label:       __('SLAs'),
  description: __('Manage Service Level Agreements of your system.'),
  preferences: { prio: 1110 }
)
Permission.create_if_not_exists(
  name:        'admin.trigger',
  label:       __('Trigger'),
  description: __('Manage triggers of your system.'),
  preferences: { prio: 1120 }
)
Permission.create_if_not_exists(
  name:        'admin.public_links',
  label:       __('Public Links'),
  description: __('Manage public links of your system.'),
  preferences: { prio: 1130 }
)
Permission.create_if_not_exists(
  name:        'admin.webhook',
  label:       __('Webhook'),
  description: __('Manage webhooks of your system.'),
  preferences: { prio: 1140 }
)
Permission.create_if_not_exists(
  name:        'admin.scheduler',
  label:       __('Scheduler'),
  description: __('Manage schedulers of your system.'),
  preferences: { prio: 1150 }
)
Permission.create_if_not_exists(
  name:        'admin.report_profile',
  label:       __('Report Profiles'),
  description: __('Manage report profiles of your system.'),
  preferences: { prio: 1160 }
)
Permission.create_if_not_exists(
  name:        'admin.time_accounting',
  label:       __('Time Accounting'),
  description: __('Manage time accounting settings of your system.'),
  preferences: { prio: 1170 }
)
Permission.create_if_not_exists(
  name:        'admin.knowledge_base',
  label:       __('Knowledge Base'),
  description: __('Create and set up Knowledge Base.'),
  preferences: { prio: 1180 }
)
Permission.create_if_not_exists(
  name:        'admin.channel_web',
  label:       __('Web'),
  description: __('Manage web channel of your system.'),
  preferences: { prio: 1190 }
)
Permission.create_if_not_exists(
  name:        'admin.channel_formular',
  label:       __('Form'),
  description: __('Manage form channel of your system.'),
  preferences: { prio: 1200 }
)
Permission.create_if_not_exists(
  name:        'admin.channel_email',
  label:       __('Email'),
  description: __('Manage email channel of your system.'),
  preferences: { prio: 1210 }
)
Permission.create_if_not_exists(
  name:        'admin.channel_sms',
  label:       __('SMS'),
  description: __('Manage SMS channel of your system.'),
  preferences: { prio: 1220 }
)
Permission.create_if_not_exists(
  name:        'admin.channel_chat',
  label:       __('Chat'),
  description: __('Manage chat channel of your system.'),
  preferences: { prio: 1230 }
)
Permission.create_if_not_exists(
  name:        'admin.channel_google',
  label:       __('Google'),
  description: __('Manage Google mail channel of your system.'),
  preferences: { prio: 1240 }
)
Permission.create_if_not_exists(
  name:        'admin.channel_microsoft365',
  label:       __('Microsoft 365'),
  description: __('Manage Microsoft 365 mail channel of your system.'),
  preferences: { prio: 1250 }
)
Permission.create_if_not_exists(
  name:        'admin.channel_microsoft_graph',
  label:       __('Microsoft Graph'),
  description: __('Manage Microsoft Graph mail channel of your system.'),
  preferences: { prio: 1255 }
)
Permission.create_if_not_exists(
  name:        'admin.channel_twitter',
  label:       __('Twitter'),
  description: __('Manage Twitter channel of your system.'),
  preferences: { prio: 1260 }
)
Permission.create_if_not_exists(
  name:        'admin.channel_facebook',
  label:       __('Facebook'),
  description: __('Manage Facebook channel of your system.'),
  preferences: { prio: 1270 }
)
Permission.create_if_not_exists(
  name:        'admin.channel_telegram',
  label:       __('Telegram'),
  description: __('Manage Telegram channel of your system.'),
  preferences: { prio: 1280 }
)
Permission.create_if_not_exists(
  name:        'admin.channel_whatsapp',
  label:       __('WhatsApp'),
  description: __('Manage WhatsApp channel of your system.'),
  preferences: { prio: 1290 }
)
Permission.create_if_not_exists(
  name:        'admin.branding',
  label:       __('Branding'),
  description: __('Manage branding settings of your system.'),
  preferences: { prio: 1300 }
)
Permission.create_if_not_exists(
  name:        'admin.system',
  label:       __('System'),
  description: __('Manage core system settings.'),
  preferences: { prio: 1310 }
)
Permission.create_if_not_exists(
  name:        'admin.security',
  label:       __('Security'),
  description: __('Manage security settings of your system.'),
  preferences: { prio: 1320 }
)
Permission.create_if_not_exists(
  name:        'admin.ticket',
  label:       __('Ticket'),
  description: __('Manage ticket settings of your system.'),
  preferences: { prio: 1330 }
)
Permission.create_if_not_exists(
  name:        'admin.ticket_auto_assignment',
  label:       __('Ticket Auto Assignment'),
  description: __('Manage ticket auto assignment settings of your system.'),
  preferences: { prio: 1331 }
)
Permission.create_if_not_exists(
  name:        'admin.ticket_duplicate_detection',
  label:       __('Ticket Duplicate Detection'),
  description: __('Manage ticket duplicate detection settings of your system.'),
  preferences: { prio: 1332 }
)
Permission.create_if_not_exists(
  name:        'admin.integration',
  label:       __('Integrations'),
  description: __('Manage integrations of your system.'),
  preferences: { prio: 1340 }
)
Permission.create_if_not_exists(
  name:        'admin.api',
  label:       __('API'),
  description: __('Manage API of your system.'),
  preferences: { prio: 1350 }
)
Permission.create_if_not_exists(
  name:        'admin.object',
  label:       __('Objects'),
  description: __('Manage object attributes of your system.'),
  preferences: { prio: 1360 }
)
Permission.create_if_not_exists(
  name:        'admin.ticket_state',
  label:       __('Ticket States'),
  description: __('Manage ticket states of your system.'),
  preferences: { prio: 1370 }
)
Permission.create_if_not_exists(
  name:        'admin.ticket_priority',
  label:       __('Ticket Priorities'),
  description: __('Manage ticket priorities of your system.'),
  preferences: { prio: 1380 }
)
Permission.create_if_not_exists(
  name:        'admin.core_workflow',
  label:       __('Core Workflows'),
  description: __('Manage core workflows of your system.'),
  preferences: { prio: 1390 }
)
Permission.create_if_not_exists(
  name:        'admin.translation',
  label:       __('Translations'),
  description: __('Manage translations of your system.'),
  preferences: { prio: 1400 }
)
Permission.create_if_not_exists(
  name:        'admin.data_privacy',
  label:       __('Data Privacy'),
  description: __('Delete existing data of your system.'),
  preferences: { prio: 1410 }
)
Permission.create_if_not_exists(
  name:        'admin.maintenance',
  label:       __('Maintenance'),
  description: __('Manage maintenance mode of your system.'),
  preferences: { prio: 1420 }
)
Permission.create_if_not_exists(
  name:        'admin.monitoring',
  label:       __('Monitoring'),
  description: __('Manage monitoring of your system.'),
  preferences: { prio: 1430 }
)
Permission.create_if_not_exists(
  name:        'admin.package',
  label:       __('Packages'),
  description: __('Manage packages of your system.'),
  preferences: { prio: 1440 }
)
Permission.create_if_not_exists(
  name:        'admin.session',
  label:       __('Sessions'),
  description: __('Manage active user sessions of your system.'),
  preferences: { prio: 1450 }
)
Permission.create_if_not_exists(
  name:        'admin.system_report',
  label:       __('System Report'),
  description: __('Manage system report of your system.'),
  preferences: { prio: 1460 }
)
Permission.create_if_not_exists(
  name:        'admin.checklist',
  label:       __('Checklists'),
  description: __('Manage ticket checklists of your system.'),
  preferences: { prio: 1465 }
)
Permission.create_if_not_exists(
  name:        'chat',
  label:       __('Chat'),
  description: __('Access to the chat interface.'),
  preferences: {
    prio:     1470,
    disabled: true,
  },
)
Permission.create_if_not_exists(
  name:        'chat.agent',
  label:       __('Agent chat'),
  description: __('Access the agent chat features.'),
  preferences: { prio: 1480 }
)
Permission.create_if_not_exists(
  name:        'cti',
  label:       __('Phone'),
  description: __('Access to the phone interface.'),
  preferences: {
    prio:     1490,
    disabled: true
  },
)
Permission.create_if_not_exists(
  name:        'cti.agent',
  label:       __('Agent phone'),
  description: __('Access the agent phone features.'),
  preferences: { prio: 1500 }
)
Permission.create_if_not_exists(
  name:        'knowledge_base',
  label:       __('Knowledge Base'),
  description: __('Access to the knowledge base interface.'),
  preferences: {
    prio:     1510,
    disabled: true,
  }
)
Permission.create_if_not_exists(
  name:        'knowledge_base.editor',
  label:       __('Knowledge Base Editor'),
  description: __('Access the knowledge base editor features.'),
  preferences: { prio: 1520 }
)
Permission.create_if_not_exists(
  name:         'knowledge_base.reader',
  label:        __('Knowledge Base Reader'),
  description:  __('Access the knowledge base reader features.'),
  allow_signup: true,
  preferences:  { prio: 1530 }
)
Permission.create_if_not_exists(
  name:        'report',
  label:       __('Report'),
  description: __('Access to the report interface.'),
  preferences: { prio: 1540 }
)
Permission.create_if_not_exists(
  name:        'ticket',
  label:       __('Ticket'),
  description: __('Access to the ticket interface.'),
  preferences: {
    prio:     1550,
    disabled: true
  },
)
Permission.create_if_not_exists(
  name:        'ticket.agent',
  label:       __('Agent tickets'),
  description: __('Access the tickets as agent based on group access.'),
  preferences: {
    prio:   1560,
    plugin: ['groups']
  },
)
Permission.create_if_not_exists(
  name:         'ticket.customer',
  label:        __('Customer tickets'),
  description:  __('Access tickets as customer.'),
  allow_signup: true,
  preferences:  { prio: 1570 }
)
Permission.create_if_not_exists(
  name:         'user_preferences',
  label:        __('Profile settings'),
  description:  __('Manage personal settings.'),
  allow_signup: true,
  preferences:  { prio: 1580 }
)
Permission.create_if_not_exists(
  name:         'user_preferences.appearance',
  label:        __('Appearance'),
  description:  __('Manage personal appearance settings.'),
  allow_signup: true,
  preferences:  { prio: 1590 }
)
Permission.create_if_not_exists(
  name:         'user_preferences.language',
  label:        __('Language'),
  description:  __('Manage personal language settings.'),
  allow_signup: true,
  preferences:  { prio: 1600 }
)
Permission.create_if_not_exists(
  name:         'user_preferences.avatar',
  label:        __('Avatar'),
  description:  __('Manage personal avatar settings.'),
  allow_signup: true,
  preferences:  { prio: 1610 }
)
Permission.create_if_not_exists(
  name:         'user_preferences.out_of_office',
  label:        __('Out of Office'),
  description:  __('Manage personal out of office settings.'),
  preferences:  {
    prio:     1620,
    required: ['ticket.agent'],
  },
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.password',
  label:        __('Password'),
  description:  __('Change personal account password.'),
  allow_signup: true,
  preferences:  { prio: 1630 }
)
Permission.create_if_not_exists(
  name:         'user_preferences.two_factor_authentication',
  label:        __('Two-factor Authentication'),
  description:  __('Manage personal two-factor authentication methods.'),
  allow_signup: true,
  preferences:  { prio: 1640 }
)
Permission.create_if_not_exists(
  name:         'user_preferences.device',
  label:        __('Devices'),
  description:  __('Manage personal devices and sessions.'),
  allow_signup: true,
  preferences:  { prio: 1650 }
)
Permission.create_if_not_exists(
  name:         'user_preferences.access_token',
  label:        __('Token Access'),
  description:  __('Manage personal API tokens.'),
  allow_signup: true,
  preferences:  { prio: 1660 }
)
Permission.create_if_not_exists(
  name:         'user_preferences.linked_accounts',
  label:        __('Linked Accounts'),
  description:  __('Manage personal linked accounts.'),
  allow_signup: true,
  preferences:  { prio: 1670 }
)
Permission.create_if_not_exists(
  name:         'user_preferences.notifications',
  label:        __('Notifications'),
  description:  __('Manage personal notifications settings.'),
  preferences:  {
    prio:     1680,
    required: ['ticket.agent'],
  },
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.overview_sorting',
  label:        __('Overviews'),
  description:  __('Manage personal overviews.'),
  preferences:  {
    prio:     1690,
    required: ['ticket.agent'],
  },
  allow_signup: true,
)
Permission.create_if_not_exists(
  name:         'user_preferences.calendar',
  label:        __('Calendar'),
  description:  __('Manage personal calendar.'),
  preferences:  {
    prio:     1700,
    required: ['ticket.agent'],
  },
  allow_signup: true,
)

Permission.create_if_not_exists(
  name:         'user_preferences.beta_ui_switch',
  label:        __('New Beta UI Switch'),
  description:  __('Manage access to new beta UI switch.'),
  preferences:  {
    prio: 1710,
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
customer.permission_grant('user_preferences.two_factor_authentication')
customer.permission_grant('user_preferences.language')
customer.permission_grant('user_preferences.linked_accounts')
customer.permission_grant('user_preferences.avatar')
customer.permission_grant('user_preferences.appearance')
customer.permission_grant('ticket.customer')
