// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useEventListener } from '@vueuse/core'
import { onActivated, onDeactivated, toValue, type MaybeRefOrGetter } from 'vue'
import { useRouter } from 'vue-router'

import { focusTableRow } from '#desktop/components/CommonTable/useTableRowNavigation.ts'
import {
  getOverlayContainerMeta,
  getRouteIdentifier,
} from '#desktop/composables/useOverlayContainer.ts'

type LeavingKey = 'ArrowLeft' | 'ArrowRight' | 'ArrowUp'

interface ListKeyboardNavigationOptions {
  list: MaybeRefOrGetter<HTMLElement | null | undefined>
  // Takes `◀` and `▶` from a row and `▲` on the first row, returns whether it moved the focus.
  onLeave?: (key: LeavingKey) => boolean
  // Takes `▲` and `▼` while nothing has the focus and the list has no rows to put it on.
  onEmpty?: () => boolean
}

const hasModifier = (event: KeyboardEvent) =>
  event.altKey || event.ctrlKey || event.metaKey || event.shiftKey

const isLeavingKey = (key: string): key is LeavingKey =>
  key === 'ArrowLeft' || key === 'ArrowRight' || key === 'ArrowUp'

const isNothingFocused = () => !document.activeElement || document.activeElement === document.body

// A dialog or flyout over the page keeps the keys, also where nothing in it has the focus. Those
//   of pages kept alive in the background stay open but are not shown.
const isOverlayOverPage = (pageIdentifier: string) =>
  (['dialog', 'flyout'] as const).some((type) => {
    const { opened, options } = getOverlayContainerMeta(type)

    return Array.from(opened.value).some(
      (name) => name.endsWith(`_${pageIdentifier}`) || !!options.get(name)?.global,
    )
  })

/**
 * Lets the arrow keys reach the rows of the page's list: while nothing has the focus, `▲` and
 *   `▼` put it on the current or first row. Native list navigation, so not a shortcut of the
 *   registry and not governed by its switch.
 */
export const useListKeyboardNavigation = ({
  list,
  onLeave,
  onEmpty,
}: ListKeyboardNavigationOptions) => {
  // The page is kept alive with others, only the shown one takes the keys.
  let isPageShown = true

  onActivated(() => {
    isPageShown = true
  })

  onDeactivated(() => {
    isPageShown = false
  })

  const router = useRouter()

  const focusList = () => focusTableRow(toValue(list))

  useEventListener(window, 'keydown', (event: KeyboardEvent) => {
    if (!isPageShown || event.defaultPrevented || hasModifier(event)) return
    if (event.key !== 'ArrowDown' && event.key !== 'ArrowUp') return
    if (!isNothingFocused() || isOverlayOverPage(getRouteIdentifier(router.currentRoute.value)))
      return

    if (focusList() || onEmpty?.()) event.preventDefault()
  })

  // The rows leave a key alone when it moves the focus nowhere within the list.
  useEventListener(list, 'keydown', (event: KeyboardEvent) => {
    if (event.defaultPrevented || hasModifier(event) || !isLeavingKey(event.key)) return
    if (!(event.target instanceof Element) || !event.target.closest('tr[data-item-id]')) return

    if (onLeave?.(event.key)) event.preventDefault()
  })

  return { focusList }
}
