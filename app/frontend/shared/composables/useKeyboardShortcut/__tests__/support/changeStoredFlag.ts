// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nextTick } from 'vue'

import { KEYBOARD_SHORTCUTS_STORAGE_KEY } from '../../useKeyboardShortcutsEnabled.ts'

// The old view writes the key with `App.LocalStorage`, i.e. JSON-encoded and without prefix.
//   Another tab's change arrives as a storage event.
export const changeStoredFlag = async (value: string | null) => {
  if (value === null) localStorage.removeItem(KEYBOARD_SHORTCUTS_STORAGE_KEY)
  else localStorage.setItem(KEYBOARD_SHORTCUTS_STORAGE_KEY, value)

  window.dispatchEvent(
    new StorageEvent('storage', {
      key: KEYBOARD_SHORTCUTS_STORAGE_KEY,
      newValue: value,
      storageArea: localStorage,
    }),
  )

  await nextTick()
}
