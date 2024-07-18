// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { computed, watch, type Ref } from 'vue'
import { useRoute } from 'vue-router'

import type { EnumTaskbarEntity } from '#shared/graphql/types.ts'

import { useUserCurrentTaskbarTabsStore } from '../stores/taskbarTabs.ts'

import type { TaskbarTabContext } from '../types.ts'

export const useTaskbarTab = (
  tabEntityType: EnumTaskbarEntity,
  context?: Ref<TaskbarTabContext>,
) => {
  const { activeTaskbarTabContext, activeTaskbarTab } = storeToRefs(
    useUserCurrentTaskbarTabsStore(),
  )

  const {
    getTaskbarTabTypePlugin,
    waitForTaskbarListLoaded,
    updateTaskbarTab,
    upsertTaskbarTab,
    deleteTaskbarTab,
  } = useUserCurrentTaskbarTabsStore()

  // Keep track of the passed context and update the store state accordingly.
  if (context) {
    watch(context, (newValue) => {
      activeTaskbarTabContext.value = newValue
    })
  }

  watch(
    () => activeTaskbarTabContext.value?.formIsDirty,
    (isDirty) => {
      if (isDirty === undefined || !activeTaskbarTab.value?.taskbarTabId) return

      // Do not update taskbar tab if the dirty flag is in the same state.
      if (activeTaskbarTab.value.dirty === isDirty) return

      updateTaskbarTab(activeTaskbarTab.value.taskbarTabId, {
        ...activeTaskbarTab.value,
        dirty: isDirty,
      })
    },
  )

  const taskbarTypePlugin = getTaskbarTabTypePlugin(tabEntityType)
  const route = useRoute()

  const tabEntityInternalId = computed(
    () => (route.params.internalId || route.params.tabId) as string,
  )

  const tabEntityKey = computed(() => {
    return taskbarTypePlugin.buildEntityTabKey(tabEntityInternalId.value)
  })

  watch(tabEntityInternalId, () => {
    upsertTaskbarTab(
      tabEntityType,
      tabEntityKey.value,
      tabEntityInternalId.value,
    )
  })

  waitForTaskbarListLoaded().then(() => {
    upsertTaskbarTab(
      tabEntityType,
      tabEntityKey.value,
      tabEntityInternalId.value,
    )
  })

  // TODO: use already existing taskbar tab
  const activeTaskbarTabFormId = computed(
    () => activeTaskbarTab.value?.formId || undefined,
  )

  const activeTaskbarTabDelete = () => {
    if (!activeTaskbarTab.value?.taskbarTabId) return

    deleteTaskbarTab(activeTaskbarTab.value?.taskbarTabId)
  }

  return {
    activeTaskbarTabFormId,
    activeTaskbarTab,
    activeTaskbarTabDelete,
  }
}
