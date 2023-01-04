// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Ref } from 'vue'
import { ref } from 'vue'

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
  }

  const goPrevious = () => {
    if (selectedIndex.value === 0) {
      selectedIndex.value = items.value.length - 1
    } else {
      selectedIndex.value -= 1
    }
    focus(selectedIndex.value)
  }

  const selectItem = (index?: number) => {
    const item = items.value[index || selectedIndex.value]
    if (item) {
      onSelect(item)
    }
  }

  const onKeyDown = (event: KeyboardEvent) => {
    if (event.key === 'ArrowDown') {
      goNext()
      return true
    }
    if (event.key === 'ArrowUp') {
      goPrevious()
      return true
    }
    if (event.key === 'Enter' || event.key === 'Tab') {
      selectItem()
      return true
    }
    return false
  }

  return {
    onKeyDown,
    selectedIndex,
    selectItem,
  }
}
