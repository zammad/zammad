// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref, watch } from 'vue'

type CommonLinkInstance = {
  isExactActive: boolean
  $el?: HTMLElement
}

export const useUserTaskbarTabLink = (exactActiveCallback?: () => void) => {
  const tabLinkInstance = ref<CommonLinkInstance>()

  watch(
    () => tabLinkInstance.value?.isExactActive,
    (isExactActive) => {
      if (!isExactActive) return

      exactActiveCallback?.()

      // Scroll the tab into view when it becomes active.
      tabLinkInstance.value?.$el?.scrollIntoView?.()
    },
  )

  return {
    tabLinkInstance,
  }
}
