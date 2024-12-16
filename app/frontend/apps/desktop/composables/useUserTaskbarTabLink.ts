// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { computed, ref, watch, type Ref } from 'vue'

import type { UserTaskbarTab } from '#desktop/components/UserTaskbarTabs/types.ts'
import { useUserCurrentTaskbarTabsStore } from '#desktop/entities/user/current/stores/taskbarTabs.ts'

type CommonLinkInstance = {
  $el?: HTMLElement
}

export const useUserTaskbarTabLink = (
  taskbarTab: Ref<UserTaskbarTab>,
  exactActiveCallback?: () => void,
) => {
  const tabLinkInstance = ref<CommonLinkInstance>()

  const { activeTaskbarTabEntityKey } = storeToRefs(
    useUserCurrentTaskbarTabsStore(),
  )

  const taskbarTabActive = computed(
    () => activeTaskbarTabEntityKey.value === taskbarTab.value.tabEntityKey,
  )

  watch(
    [taskbarTabActive, tabLinkInstance],
    ([isActive, instance]) => {
      if (!isActive || !instance) return

      exactActiveCallback?.()

      // Scroll the tab into view when it becomes active and is not visible within the viewport.
      /**
       * @checkVisibility supported by all major browser
       * @source https://caniuse.com/?search=checkVisibility
       * In case if not we return true
       */
      setTimeout(() => {
        // We have to set this to the event loop tick to wait the route has been updated
        if (instance.$el?.checkVisibility?.() ?? true) {
          instance.$el?.scrollIntoView?.({ block: 'nearest' })
        }
      }, 0)
    },
    { immediate: true, flush: 'post' },
  )

  return {
    tabLinkInstance,
    taskbarTabActive,
  }
}
