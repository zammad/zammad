// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { AvatarMenuPlugin } from './index.ts'

export default <AvatarMenuPlugin>{
  key: 'keyboard-shortcuts',
  label: __('Keyboard shortcuts'),
  // TODO: Remove once the feature is implemented and the menu item should be shown.
  show: () => false,
  onClick: () => {
    console.log('OPEN KEYBOARD SHORTCUTS DIALOG')
  },
  icon: 'keyboard',
  order: 200,
  permission: ['admin.*', 'ticket.agent'],
}
