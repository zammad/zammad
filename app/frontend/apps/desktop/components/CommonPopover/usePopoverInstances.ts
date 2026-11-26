// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref, toValue } from 'vue'

import type { CommonPopoverInternalInstance } from './types.ts'
import type { ComputedRef } from 'vue'

const instances = ref(new Set<CommonPopoverInternalInstance>()) as unknown as ComputedRef<
  Set<CommonPopoverInternalInstance>
>

export const usePopoverInstances = () => {
  const isOpened = computed(() => [...instances.value].some((instance) => toValue(instance.isOpen)))

  return {
    isOpened,
    instances,
  }
}

export const closeOpenPopovers = () => {
  // Exposed instances are marked raw and keep their ref; others come out of the set unwrapped.
  instances.value.forEach((instance) => {
    if (toValue(instance.isOpen)) instance.closePopover()
  })
}
