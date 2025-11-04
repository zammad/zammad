// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { ref, computed, type Ref } from 'vue'

import { i18n } from '#shared/i18n/index.ts'

import { useAnnouncer } from '#desktop/composables/accessibility/useAnnouncer.ts'

export function useKeyboardKeysForDragAndDrop({
  items,
  onReorder,
}: {
  items: Ref<string[]>
  onReorder?: (newOrder: string[]) => void
}) {
  const { announce } = useAnnouncer()

  const focusedItemIndex = ref<number | null>(null)
  const selectedItemIndex = ref<number | null>(null)

  let listHasFocus = false

  const focusedItemId = computed(() =>
    focusedItemIndex.value !== null && items.value.length > 0
      ? `item-${items.value[focusedItemIndex.value]}`
      : undefined,
  )

  const handleKeydown = (event: KeyboardEvent) => {
    if (!listHasFocus) return

    const itemCount = items.value.length

    if (!itemCount) return

    const currentItemIndex = focusedItemIndex.value

    const handleSelection = () => {
      if (currentItemIndex === null) return // No item focused, do nothing

      if (selectedItemIndex.value === null) {
        // No selection: Select the current item
        selectedItemIndex.value = currentItemIndex
        announce(
          i18n.t(
            '%s selected. Use arrow keys to choose drop position, then press Space.',
            items.value[currentItemIndex],
          ),
        )
      } else if (selectedItemIndex.value === currentItemIndex) {
        // Same item: Deselect
        selectedItemIndex.value = null
        announce(i18n.t('%s deselected.', items.value[currentItemIndex]))
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
            fromValue,
            toValue,
            fromValue,
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

        // moves focus to the next item (wraps to start)
        focusedItemIndex.value = currentItemIndex === null ? 0 : (currentItemIndex + 1) % itemCount
        announce(i18n.t('Focus on %s', items.value[focusedItemIndex.value]))
        break
      }
      case 'ArrowUp': {
        event.preventDefault()

        // moves focus to the previous item (wraps to end)
        focusedItemIndex.value =
          currentItemIndex === null ? itemCount - 1 : (currentItemIndex - 1 + itemCount) % itemCount
        announce(i18n.t('Focus on %s', items.value[focusedItemIndex.value] as string))
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
          announce(i18n.t('Selection cancelled for %s.', items.value[selectedItemIndex.value]))
          selectedItemIndex.value = null
        } else {
          announce(__('Escape pressed. No item selected.'))
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
      __(
        'Sortable list focused. Use up and down arrows to navigate items. Press Space to select and item and again on another item to swap them.',
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
