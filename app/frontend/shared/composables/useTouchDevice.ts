// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'
import { tryOnScopeDispose } from '@vueuse/shared'

export const useTouchDevice = () => {
  const isTouchDevice = ref(false)

  if (window) {
    let mediaQuery: MediaQueryList

    const observeCallback = () => {
      isTouchDevice.value = window.matchMedia('(pointer: coarse)').matches
      mediaQuery?.removeEventListener('change', observeCallback)
      mediaQuery = window.matchMedia('(pointer: coarse)')
      mediaQuery.addEventListener('change', observeCallback, { once: true })
    }

    observeCallback()

    tryOnScopeDispose(() => {
      mediaQuery?.removeEventListener('change', observeCallback)
    })
  }

  return {
    isTouchDevice,
  }
}
