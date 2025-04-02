// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import type { Ref } from 'vue'

// we don't use useTraverOptions here because we don't FOCUS elements, just traverse
export default function useNavigateOptions(
  items: Ref<unknown[]>,
  onSelect: (item: unknown) => void,
) {
  const selectedIndex = ref(0)

  const focus = (index: number) => {
    const element = document.querySelector(`#mention-${index}`)
    element?.scrollIntoView({ block: 'nearest' })
  }

  const goNext = () => {
    if (selectedIndex.value === items.value.length - 1) {
      selectedIndex.value = 0
    } else {
      selectedIndex.value += 1
    }
    focus(selectedIndex.value)
    return selectedIndex.value in items.value
  }

  const goPrevious = () => {
    if (selectedIndex.value === 0) {
      selectedIndex.value = items.value.length - 1
    } else {
      selectedIndex.value -= 1
    }
    focus(selectedIndex.value)
    return selectedIndex.value in items.value
  }

  const selectItem = (index?: number) => {
    const item = items.value[index || selectedIndex.value]
    if (item) {
      onSelect(item)
      return true
    }
    return false
  }

  const onKeyDown = (event: KeyboardEvent) => {
    if (event.key === 'ArrowDown') {
      return goNext()
    }
    if (event.key === 'ArrowUp') {
      return goPrevious()
    }
    if (event.key === 'Enter' || event.key === 'Tab') {
      return selectItem()
    }
    return false
  }

  return {
    onKeyDown,
    selectedIndex,
    selectItem,
  }
}
