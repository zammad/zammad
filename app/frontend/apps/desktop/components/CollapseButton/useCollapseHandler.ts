// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage } from '@vueuse/core'
import { onMounted, type Ref, ref, watch } from 'vue'

import emitter from '#shared/utils/emitter.ts'

import type { CollapseOptions, CollapseEmit } from './types.ts'

/**
 * @args emit - The emit function from the setup function
 * @args options.storageKey - The key to store the collapse state in local storage
 * * */
export const useCollapseHandler = (
  emit: CollapseEmit,
  options?: CollapseOptions,
) => {
  let isCollapsed: Ref<boolean>

  if (options?.storageKey) {
    isCollapsed = useLocalStorage(options.storageKey, false)
  } else {
    isCollapsed = ref(false)
  }

  const callEmit = () =>
    isCollapsed.value ? emit('collapse', true) : emit('expand', true)

  const toggleCollapse = () => {
    isCollapsed.value = !isCollapsed.value

    callEmit()
  }

  emitter.on('expand-collapsed-content', (name: string) => {
    if (options?.name === name && isCollapsed.value) toggleCollapse()
  })

  onMounted(() => {
    // Set up watcher on the local storage value, so other browser tabs can sync their collapse states.
    if (options?.storageKey) {
      watch(
        isCollapsed,
        () => {
          callEmit()
        },
        {
          immediate: true,
        },
      )
    }
  })

  return {
    isCollapsed,
    toggleCollapse,
  }
}
