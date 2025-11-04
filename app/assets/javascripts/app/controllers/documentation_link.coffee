App.Config.set('admin_docs', {
  name: __('Admin Documentation'),
  permission: ['admin.*'],
  target: 'https://admin-docs.zammad.org/en/latest',
  containerClass: 'navbar-link-admin-docs',
  prio: 10,
  external: true,
  parent: '#current_user',
  translate: true,
  iconClass: 'external'
}, 'NavBarRight')

App.Config.set('agent_docs', {
  name: __('User Documentation'),
  permission: ['ticket.agent', 'report', 'knowledge_base.*', 'chat.agent', 'cti.agent'],
  target: 'https://user-docs.zammad.org/en/latest',
  containerClass: 'navbar-link-agent-docs',
  prio: 11,
  external: true,
  parent: '#current_user',
  translate: true,
  iconClass: 'external'
}, 'NavBarRight')
