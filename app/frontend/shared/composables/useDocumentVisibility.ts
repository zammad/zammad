// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useDocumentVisibility as useVisibilityState } from '@vueuse/core'
import { tryOnScopeDispose } from '@vueuse/shared'
import { computed, watch } from 'vue'

export const useDocumentVisibility = () => {
  const visibilityState = useVisibilityState()

  const isVisible = computed(() => visibilityState.value === 'visible')

  let deferredCallback: (() => void) | null = null
  let deferredTimeout: ReturnType<typeof setTimeout> | undefined

  const clearDeferred = () => {
    deferredCallback = null
    clearTimeout(deferredTimeout)
  }

  // Runs the callback right away in a visible document, otherwise once the
  //   document is looked at again, or never when that takes longer than the
  //   timeout. One callback is held at a time; a later call replaces it.
  const whenVisible = (callback: () => void, timeout?: number) => {
    if (isVisible.value) {
      callback()
      return
    }

    clearDeferred()
    deferredCallback = callback

    if (timeout !== undefined) deferredTimeout = setTimeout(clearDeferred, timeout)
  }

  watch(isVisible, (visible) => {
    if (!visible || !deferredCallback) return

    const callback = deferredCallback

    clearDeferred()
    callback()
  })

  tryOnScopeDispose(clearDeferred)

  return {
    visibilityState,
    isVisible,
    whenVisible,
  }
}
