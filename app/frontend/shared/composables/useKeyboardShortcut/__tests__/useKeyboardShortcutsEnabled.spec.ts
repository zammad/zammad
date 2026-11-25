// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nextTick } from 'vue'

import {
  KEYBOARD_SHORTCUTS_STORAGE_KEY,
  useKeyboardShortcutsEnabled,
} from '../useKeyboardShortcutsEnabled.ts'

import { changeStoredFlag } from './support/changeStoredFlag.ts'

describe('useKeyboardShortcutsEnabled', () => {
  beforeEach(async () => {
    await changeStoredFlag(null)
  })

  it('is enabled while the key is absent, without writing it', () => {
    const { isEnabled } = useKeyboardShortcutsEnabled()

    expect(isEnabled.value).toBe(true)
    expect(localStorage.getItem(KEYBOARD_SHORTCUTS_STORAGE_KEY)).toBeNull()
  })

  it('writes false in the format of the old desktop view when disabling', async () => {
    const { isEnabled } = useKeyboardShortcutsEnabled()

    isEnabled.value = false
    await nextTick()

    expect(isEnabled.value).toBe(false)
    expect(localStorage.getItem(KEYBOARD_SHORTCUTS_STORAGE_KEY)).toBe('false')
  })

  it('removes the key when enabling', async () => {
    const { isEnabled } = useKeyboardShortcutsEnabled()

    isEnabled.value = false
    await nextTick()

    isEnabled.value = true
    await nextTick()

    expect(isEnabled.value).toBe(true)
    expect(localStorage.getItem(KEYBOARD_SHORTCUTS_STORAGE_KEY)).toBeNull()
  })

  it('picks up a change from another tab', async () => {
    const { isEnabled } = useKeyboardShortcutsEnabled()

    await changeStoredFlag('false')

    expect(isEnabled.value).toBe(false)

    await changeStoredFlag(null)

    expect(isEnabled.value).toBe(true)
  })
})
