// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { AvatarMenuPlugin } from './index.ts'

export default <AvatarMenuPlugin>{
  key: 'user-documentation',
  label: __('User Documentation'),
  permission: ['ticket.agent', 'report', 'knowledge_base.*', 'chat.agent', 'cti.agent'],
  link: 'https://next.zammad.org/en/documentation/use/general.html', // TODO: change link when new user documentation is released
  linkExternal: true,
  openInNewTab: true,
  icon: 'book',
  order: 80,
}
