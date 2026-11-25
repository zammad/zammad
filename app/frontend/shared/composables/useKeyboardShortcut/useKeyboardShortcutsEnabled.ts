// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createGlobalState, StorageSerializers, useLocalStorage } from '@vueuse/core'
import { computed } from 'vue'

// Shared with the old desktop view, in its format: the key is absent while shortcuts are on and
//   holds JSON `false` while they are off. It is per browser, not per account, and has no user
//   prefix. Write it only through `isEnabled`, so that the format stays in one place.
export const KEYBOARD_SHORTCUTS_STORAGE_KEY = 'keyboardShortcuts'

export const useKeyboardShortcutsEnabled = createGlobalState(() => {
  const storedValue = useLocalStorage<unknown>(KEYBOARD_SHORTCUTS_STORAGE_KEY, null, {
    serializer: StorageSerializers.object,
    writeDefaults: false,
  })

  const isEnabled = computed({
    get: () => storedValue.value !== false,
    set: (enabled) => {
      storedValue.value = enabled ? null : false
    },
  })

  return { isEnabled }
})
