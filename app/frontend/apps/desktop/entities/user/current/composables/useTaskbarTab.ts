// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { computed, watch, type Ref } from 'vue'

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

  const { updateTaskbarTab, deleteTaskbarTab } =
    useUserCurrentTaskbarTabsStore()

  // Keep track of the passed context and update the store state accordingly.
  if (context) {
    watch(
      context,
      (newValue) => {
        activeTaskbarTabContext.value = newValue
      },
      { immediate: true },
    )
  }

  watch(
    () => activeTaskbarTabContext.value?.formIsDirty,
    (isDirty) => {
      if (isDirty === undefined || !activeTaskbarTab.value?.taskbarTabId) return

      if (activeTaskbarTab.value.dirty === isDirty) return

      updateTaskbarTab(activeTaskbarTab.value.taskbarTabId, {
        ...activeTaskbarTab.value,
        dirty: isDirty,
      })
    },
  )

  const activeTaskbarTabFormId = computed(
    () => activeTaskbarTab.value?.formId || undefined,
  )

  const activeTaskbarTabNewArticlePresent = computed(
    () => !!activeTaskbarTab.value?.formNewArticlePresent,
  )

  const activeTaskbarTabDelete = () => {
    if (!activeTaskbarTab.value?.taskbarTabId) return

    deleteTaskbarTab(activeTaskbarTab.value?.taskbarTabId)
  }

  return {
    activeTaskbarTabFormId,
    activeTaskbarTabNewArticlePresent,
    activeTaskbarTab,
    activeTaskbarTabDelete,
  }
}
