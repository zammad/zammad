// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/
import { useLocalStorage } from '@vueuse/core'
import { nextTick, onMounted, type Ref, ref } from 'vue'

interface Emits {
  (event: 'collapse', arg: boolean): void
  (event: 'expand', arg: boolean): void
}

/**
 * @args emit - The emit function from the setup function
 * @args options.storageKey - The key to store the collapse state in local storage
 * * */
export const useCollapseHandler = (
  emit: Emits,
  options?: { storageKey: string },
) => {
  let isCollapsed: Ref<boolean>
  if (options?.storageKey) {
    isCollapsed = useLocalStorage(options.storageKey, false)
  } else {
    isCollapsed = ref(false)
  }

  const toggleCollapse = () => {
    isCollapsed.value = !isCollapsed.value
    if (isCollapsed.value) {
      emit('collapse', true)
    } else {
      emit('expand', true)
    }
  }

  onMounted(() => {
    if (options?.storageKey) {
      nextTick(() => {
        // Share state on initial load
        if (isCollapsed.value) emit('collapse', true)
        else emit('expand', true)
      })
    }
  })

  return {
    isCollapsed,
    toggleCollapse,
  }
}
