// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nextTick, ref, type Ref } from 'vue'

import testFlags from '#shared/utils/testFlags.ts'

export interface UseDatePanelOptions {
  input: Ref<HTMLElement | null>
  disabled: () => boolean
  // Runs before the panel renders, `onOpened` once it has.
  onOpen?: () => void
  onOpened?: () => void
  onClose?: () => void
}

// Whether the panel of a date field is shown, shared by the desktop and the mobile input. The
// test flags tell the Capybara helpers that the panel has rendered or gone.
export const useDatePanel = (options: UseDatePanelOptions) => {
  const isOpen = ref(false)

  const open = () => {
    if (isOpen.value || options.disabled()) return

    options.onOpen?.()
    isOpen.value = true

    nextTick(() => {
      options.onOpened?.()
      testFlags.set('field-date.opened')
    })
  }

  const close = ({ refocus = false } = {}) => {
    if (!isOpen.value) return

    isOpen.value = false
    options.onClose?.()

    nextTick(() => {
      if (refocus) options.input.value?.focus()
      testFlags.set('field-date.closed')
    })
  }

  return { close, isOpen, open }
}
