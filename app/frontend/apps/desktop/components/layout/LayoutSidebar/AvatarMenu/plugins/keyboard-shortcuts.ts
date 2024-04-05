// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { AvatarMenuPlugin } from './index.ts'

export default <AvatarMenuPlugin>{
  key: 'keyboard-shortcuts',
  label: __('Keyboard shortcuts'),
  onClick: () => {
    console.log('OPEN KEYBOARD SHORTCUTS DIALOG')
  },
  icon: 'keyboard',
  order: 200,
}
