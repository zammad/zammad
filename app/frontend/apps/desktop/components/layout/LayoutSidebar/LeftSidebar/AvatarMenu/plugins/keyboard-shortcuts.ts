// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { openKeyboardShortcutsDialog } from '#desktop/components/KeyboardShortcutsDialog/useKeyboardShortcutsDialog.ts'

import type { AvatarMenuPlugin } from './index.ts'

export default <AvatarMenuPlugin>{
  key: 'keyboard-shortcuts',
  label: __('Keyboard shortcuts'),
  onClick: openKeyboardShortcutsDialog,
  icon: 'keyboard',
  order: 200,
}
