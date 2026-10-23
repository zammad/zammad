// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { watchOnce } from '@vueuse/shared'
import { computed, inject, provide, ref, watch, type InjectionKey, type Ref } from 'vue'

import type { UserTaskbarTab } from '#desktop/components/UserTaskbarTabs/types.ts'

type CommonLinkInstance = {
  $el?: HTMLElement
}

// Injected instead of read from the taskbar tabs store, which imports the tab components.
const ACTIVE_TASKBAR_TAB_ENTITY_KEY = Symbol('active-taskbar-tab-entity-key') as InjectionKey<
  Ref<string | undefined>
>

export const provideActiveTaskbarTabEntityKey = (
  activeTaskbarTabEntityKey: Ref<string | undefined>,
) => provide(ACTIVE_TASKBAR_TAB_ENTITY_KEY, activeTaskbarTabEntityKey)

export const useUserTaskbarTab = (
  taskbarTab: Ref<UserTaskbarTab>,
  exactActiveCallback?: () => void,
) => {
  const tabLinkInstance = ref<CommonLinkInstance>()

  const activeTaskbarTabEntityKey = inject(ACTIVE_TASKBAR_TAB_ENTITY_KEY, ref())

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

  const isTaskbarTabLoaded = ref(taskbarTabActive.value)

  if (!isTaskbarTabLoaded.value) {
    watchOnce(taskbarTabActive, () => {
      isTaskbarTabLoaded.value = true
    })
  }

  return {
    tabLinkInstance,
    taskbarTabActive,
    isTaskbarTabLoaded,
  }
}
