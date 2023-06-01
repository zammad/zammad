// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref } from 'vue'
import type { CommonSelectInternalInstance } from './types.ts'

const instances = ref(new Set<CommonSelectInternalInstance>())

export const useCommonSelect = () => {
  const isOpened = computed(() => {
    for (const instance of instances.value) {
      if (instance.isOpen.value) {
        return true
      }
    }
    return false
  })

  return {
    isOpened,
    instances,
  }
}
