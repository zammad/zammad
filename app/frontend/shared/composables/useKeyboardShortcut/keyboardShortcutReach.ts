// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { KeyboardShortcutReachGuard } from './types.ts'
import type { InjectionKey } from 'vue'

export const KEYBOARD_SHORTCUT_REACH_GUARD = Symbol(
  'keyboard-shortcut-reach-guard',
) as InjectionKey<KeyboardShortcutReachGuard>
