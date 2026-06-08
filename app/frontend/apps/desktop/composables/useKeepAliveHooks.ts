// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nextTick, onActivated, onDeactivated, onMounted, shallowRef } from 'vue'

// There is currently a bug in vue -> https://github.com/vuejs/core/issues/10806
// Whenever you call onActivated in a child component, which rerenders based on a condition
// onActivated is not called again on initial render.
export const useKeepAliveHooks = (callbacks: {
  onInitialActivated?: () => void
  onActivated?: () => void
  onDeactivated?: () => void
  onReactivated?: () => void
}) => {
  const initialActivationDone = shallowRef(false)

  onMounted(() => {
    nextTick(() => {
      initialActivationDone.value = true
    })

    callbacks.onInitialActivated?.()
  })

  onActivated(() => {
    callbacks.onActivated?.()

    if (!initialActivationDone.value) return

    callbacks.onReactivated?.()
  })

  onDeactivated(() => {
    callbacks.onDeactivated?.()
  })

  return { initialActivationDone }
}
