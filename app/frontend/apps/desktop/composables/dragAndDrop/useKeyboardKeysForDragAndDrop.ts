// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref, computed, toValue } from 'vue'

import { i18n } from '#shared/i18n/index.ts'

import { useAnnouncer } from '#desktop/composables/accessibility/useAnnouncer.ts'

import type { ShallowOrDeepRef } from '@vueuse/shared'
import type { MaybeRefOrGetter } from 'vue'

/**
 * Where the next focus goes when the list is laid out in `columns` columns and the arrow key
 * asks for another row.
 *
 * Wraps within the column rather than through the array: from the bottom row up and down lead
 * back to the top of the same column, the way every other grid does it. Cells the last row does
 * not have are skipped - a grid whose last row is only half full would otherwise stop dead below
 * its gaps - which is also why this steps row by row instead of computing the target outright.
 */
const moveByRow = (index: number, rowDelta: number, itemCount: number, columns: number) => {
  const rowCount = Math.ceil(itemCount / columns)
  const column = index % columns

  let row = Math.floor(index / columns)

  for (let step = 0; step < rowCount; step += 1) {
    row = (row + rowDelta + rowCount) % rowCount

    const candidate = row * columns + column

    if (candidate < itemCount) return candidate
  }

  return index
}

export function useKeyboardKeysForDragAndDrop<T extends object | string>({
  items,
  onReorder,
  getValue = (item) => (typeof item === 'string' ? item : String(item)),
  getId = getValue,
  parent,
}: {
  items: ShallowOrDeepRef<T[]>
  onReorder?: (newOrder: T[]) => void
  getValue?: (item: T) => string
  /**
   * Builds the `item-${…}` suffix `aria-activedescendant` points at, so it must match whatever the
   * rendered item's `id` is built from - a human-readable `getValue` (e.g. a title) is not
   * guaranteed unique or stable and, unless it already doubles as the DOM id, resolves to an
   * element that does not exist. Defaults to `getValue` for callers where the two coincide.
   */
  getId?: (item: T) => string
  /**
   * The list element, for a list that is laid out as a grid - the knowledge base categories are,
   * its answers are a single column. Read for its column count, so up and down move by a whole
   * row there instead of by one tile, and for its writing direction, so left and right follow the
   * reading order rather than the array.
   *
   * Without it every list counts as one column, which is what a plain list wants: there all four
   * arrows then step by one item, as up and down always did.
   */
  parent?: MaybeRefOrGetter<HTMLElement | null | undefined>
}) {
  const { announce } = useAnnouncer()

  const focusedItemIndex = ref<number | null>(null)
  const selectedItemIndex = ref<number | null>(null)

  const getActiveItem = () => items.value[focusedItemIndex.value ?? 0]
  const getActiveItemValue = () => getValue(getActiveItem())

  let listHasFocus = false

  const focusedItemId = computed(() =>
    focusedItemIndex.value !== null && items.value.length > 0
      ? `item-${getId(getActiveItem())}`
      : undefined,
  )

  /**
   * Taken off the rendered element instead of off the breakpoints the grid is written in: it
   * sizes itself by its container, and `grid-template-columns` is the one place where the number
   * of columns is already resolved for the width it currently has. A non-grid element reports
   * `none` there, i.e. the single column a plain list is.
   */
  const gridGeometry = () => {
    const element = toValue(parent)

    if (!element) return { columns: 1, rtl: false }

    const { gridTemplateColumns, direction } = window.getComputedStyle(element)

    const columns = (gridTemplateColumns || '').split(' ').filter(Boolean).length

    return { columns: Math.max(columns, 1), rtl: direction === 'rtl' }
  }

  const handleKeydown = (event: KeyboardEvent) => {
    if (!listHasFocus) return

    const itemCount = items.value.length

    if (!itemCount) return

    const currentItemIndex = focusedItemIndex.value

    const { columns, rtl } = gridGeometry()

    const moveFocusTo = (index: number) => {
      focusedItemIndex.value = index
      announce(i18n.t('Focus on %s', getActiveItemValue()))
    }

    // Nothing focused yet: a forward key starts at the first item, a backward one at the last.
    const firstItemFor = (delta: number) => (delta > 0 ? 0 : itemCount - 1)

    // Along the list, in reading order, wrapping around its ends.
    const moveByItem = (delta: number) =>
      moveFocusTo(
        currentItemIndex === null
          ? firstItemFor(delta)
          : (currentItemIndex + delta + itemCount) % itemCount,
      )

    const moveByRowFrom = (delta: number) =>
      moveFocusTo(
        currentItemIndex === null
          ? firstItemFor(delta)
          : moveByRow(currentItemIndex, delta, itemCount, columns),
      )

    const handleSelection = () => {
      if (currentItemIndex === null) return // No item focused, do nothing

      if (selectedItemIndex.value === null) {
        // No selection: Select the current item
        selectedItemIndex.value = currentItemIndex
        announce(
          i18n.t(
            '%s selected. Use arrow keys to choose drop position, then press Space.',
            getActiveItemValue(),
          ),
        )
      } else if (selectedItemIndex.value === currentItemIndex) {
        // Same item: Deselect
        selectedItemIndex.value = null
        announce(i18n.t('%s deselected.', getActiveItemValue()))
      } else {
        // Different item: Swap positions
        const fromIndex = selectedItemIndex.value
        const toIndex = currentItemIndex

        const newItems = [...items.value]
        const fromValue = newItems[fromIndex]
        const toValue = newItems[toIndex]

        newItems[fromIndex] = toValue
        newItems[toIndex] = fromValue
        items.value = newItems

        onReorder?.(newItems)

        announce(
          i18n.t(
            'Swapped %s with %s. %s moved to position %s.',
            getValue(fromValue),
            getValue(toValue),
            getValue(fromValue),
            toIndex + 1,
          ),
        )

        selectedItemIndex.value = null
        focusedItemIndex.value = toIndex
      }
    }

    switch (event.key) {
      case 'ArrowDown': {
        event.preventDefault()

        // moves focus one row down (wraps to the top of the same column)
        moveByRowFrom(1)
        break
      }
      case 'ArrowUp': {
        event.preventDefault()

        // moves focus one row up (wraps to the bottom of the same column)
        moveByRowFrom(-1)
        break
      }
      case 'ArrowRight': {
        event.preventDefault()

        // moves focus to the item that follows in reading order (wraps to start)
        moveByItem(rtl ? -1 : 1)
        break
      }
      case 'ArrowLeft': {
        event.preventDefault()

        // moves focus to the item that precedes in reading order (wraps to end)
        moveByItem(rtl ? 1 : -1)
        break
      }
      case ' ': {
        event.preventDefault()
        handleSelection()
        break
      }
      // :TODO TESTING ISSUR related -> investigate for issue in upstream libraries
      // In js-dom with testing-library the key mapping seems to be buggy key reference sane as code
      // https://github.com/testing-library/user-event/blob/main/src/keyboard/keyMap.ts should be
      // line 25   {code: 'Space', key: ' '},
      case 'Space': {
        event.preventDefault()
        handleSelection()
        break
      }
      case 'Escape': {
        event.preventDefault()

        if (selectedItemIndex.value !== null) {
          announce(i18n.t('Selection cancelled for %s.', getActiveItemValue()))
          selectedItemIndex.value = null
        } else {
          announce(i18n.t('Escape pressed. No item selected.'))
          focusedItemIndex.value = null
        }
        break
      }
    }
  }

  // Focus handler
  const handleFocus = () => {
    listHasFocus = true
    if (focusedItemIndex.value === null && items.value.length > 0) {
      focusedItemIndex.value = 0
    }
    announce(
      gridGeometry().columns > 1
        ? i18n.t(
            'Sortable grid focused. Use the arrow keys to navigate items. Press Space to select an item and again on another item to swap them.',
          )
        : i18n.t(
            'Sortable list focused. Use up and down arrows to navigate items. Press Space to select an item and again on another item to swap them.',
          ),
    )
  }

  const handleBlur = () => {
    // Optionally clear focus
    focusedItemIndex.value = null
    selectedItemIndex.value = null
    listHasFocus = false
  }

  return {
    focusedItemIndex,
    selectedItemIndex,
    focusedItemId,
    handleKeydown,
    handleFocus,
    handleBlur,
  }
}
