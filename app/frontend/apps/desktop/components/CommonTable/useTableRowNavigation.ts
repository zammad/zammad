// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useEventListener } from '@vueuse/core'
import { ref, type MaybeRefOrGetter } from 'vue'

const ITEM_ROW = 'tr[data-item-id]'

export const CURRENT_ROW_ATTRIBUTE = 'data-current-row'

const findItemRow = (element: EventTarget | null) =>
  element instanceof Element ? element.closest<HTMLElement>(ITEM_ROW) : null

const focusRow = (row: HTMLElement) => {
  row.focus({ preventScroll: true })
  row.scrollIntoView?.({ block: 'nearest' })
}

/**
 * Focuses the current row of the table in the container, or its first row, so the arrow keys
 *   can continue from there.
 */
export const focusTableRow = (container?: HTMLElement | null) => {
  const row =
    container?.querySelector<HTMLElement>(`tbody ${ITEM_ROW}[${CURRENT_ROW_ATTRIBUTE}]`) ??
    container?.querySelector<HTMLElement>(`tbody ${ITEM_ROW}`)

  if (!row) return false

  focusRow(row)

  return true
}

/**
 * Moves the focus over the item rows of a table with the arrow keys, `Home` and `End`, skipping
 *   group rows. The row that has the focus, or an element in it, is the current row.
 *   A key that moves nowhere is left alone, so the page around the table can take it.
 */
export const useTableRowNavigation = (
  rowsContainer: MaybeRefOrGetter<HTMLElement | null | undefined>,
  toggleRow: (itemId: string) => boolean,
) => {
  const currentRowId = ref<string>()

  const onRowsFocusin = (event: FocusEvent) => {
    const row = findItemRow(event.target)

    if (row?.dataset.itemId) currentRowId.value = row.dataset.itemId
  }

  const onRowsKeydown = (event: KeyboardEvent) => {
    if (event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return

    const row = findItemRow(event.target)
    if (!row?.parentElement) return

    if (event.key === ' ') {
      // On an element in the row, the key belongs to that element.
      if (event.target === row && row.dataset.itemId && toggleRow(row.dataset.itemId))
        event.preventDefault()

      return
    }

    const rows = Array.from(row.parentElement.querySelectorAll<HTMLElement>(`:scope > ${ITEM_ROW}`))
    const index = rows.indexOf(row)

    const target = {
      ArrowDown: rows[index + 1],
      ArrowUp: rows[index - 1],
      Home: rows[0],
      End: rows.at(-1),
    }[event.key]

    if (!target) return

    event.preventDefault()
    focusRow(target)
  }

  useEventListener(rowsContainer, 'focusin', onRowsFocusin)
  useEventListener(rowsContainer, 'keydown', onRowsKeydown)

  return { currentRowId }
}
