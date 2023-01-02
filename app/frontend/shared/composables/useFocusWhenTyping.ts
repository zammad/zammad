// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import stopEvent from '@shared/utils/events'
import { getFocusableElements } from '@shared/utils/getFocusableElements'
import { onKeyStroke, unrefElement } from '@vueuse/core'
import type { MaybeComputedRef } from '@vueuse/core'
import type { Ref } from 'vue'

// https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Roles/listbox_role#keyboard_interactions
// - Type-ahead is recommended for all listboxes, especially those with more than seven options
export const useFocusWhenTyping = (
  container: MaybeComputedRef<HTMLElement | undefined | null>,
) => {
  let filter = ''
  let timeout = 0

  onKeyStroke(
    (e) => {
      // only process alphanumeric keys
      if (e.location !== 0 || (e.key.length !== 1 && e.key !== 'Backspace'))
        return

      if (e.key === ' ') {
        if (filter === '') return // don't start timeout, if not filtering
        stopEvent(e) // don't select option, if in the process of filtering
      }

      window.clearTimeout(timeout)

      timeout = window.setTimeout(() => {
        const option = getFocusableElements(unrefElement(container)).find(
          (el) => {
            const content = el.textContent?.toLowerCase().trim() ?? ''
            const filtered = filter.toLowerCase()
            if (content.startsWith(filtered)) return true
            const label =
              el.getAttribute('aria-label')?.toLowerCase().trim() ?? ''
            return label.startsWith(filtered)
          },
        )
        option?.focus()
        filter = ''
      }, 250)

      if (e.key === 'Backspace') filter = filter.slice(0, filter.length - 1)
      else filter += e.key
    },
    { target: container as Ref<EventTarget> },
  )
}
