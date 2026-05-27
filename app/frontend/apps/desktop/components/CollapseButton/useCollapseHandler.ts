// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { useOnEmitter } from '#shared/composables/useOnEmitter.ts'

import type { CollapseOptions, CollapseCallbacks } from './types.ts'

export const useCollapseHandler = (callbacks: CollapseCallbacks, options?: CollapseOptions) => {
  const isCollapsed = options?.isCollapsed ?? ref(false)

  const toggleCollapse = (collapse?: boolean) => {
    const nextCollapsed = collapse ?? !isCollapsed.value

    if (nextCollapsed === isCollapsed.value) return

    isCollapsed.value = nextCollapsed
    return isCollapsed.value ? callbacks.collapse() : callbacks.expand()
  }

  useOnEmitter('expand-collapsed-content', (name) => {
    if (options?.name === name && isCollapsed.value) toggleCollapse()
  })

  return {
    isCollapsed,
    toggleCollapse,
  }
}
