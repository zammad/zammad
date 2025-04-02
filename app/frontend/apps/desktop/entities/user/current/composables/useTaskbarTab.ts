// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { isEqual } from 'lodash-es'
import { storeToRefs } from 'pinia'
import {
  computed,
  inject,
  provide,
  watch,
  type ComputedRef,
  type InjectionKey,
  type Ref,
} from 'vue'

import type { UserTaskbarTab } from '#desktop/components/UserTaskbarTabs/types.ts'

import { useUserCurrentTaskbarTabsStore } from '../stores/taskbarTabs.ts'

import type { TaskbarTabContext } from '../types.ts'

interface CurrentTaskbarTabData {
  currentTaskbarTab: ComputedRef<UserTaskbarTab | undefined>
  currentTaskbarTabId: ComputedRef<string | undefined>
  currentTaskbarEntityKey: string | undefined
  currentTaskbarTabFormId: ComputedRef<string | undefined>
  currentTaskbarTabNewArticlePresent: ComputedRef<boolean>
}

export const CURRENT_TASKBAR_TAB_KEY = Symbol(
  'current-taskbar-tab',
) as InjectionKey<CurrentTaskbarTabData>

export const initializeCurrentTaskbarTab = (taskbarEntityKey?: string) => {
  const { taskbarTabListByTabEntityKey } = storeToRefs(
    useUserCurrentTaskbarTabsStore(),
  )

  const currentTaskbarTab = computed<UserTaskbarTab | undefined>(
    (existingTaskbarTab) => {
      if (!taskbarEntityKey) return

      if (
        existingTaskbarTab &&
        isEqual(
          existingTaskbarTab,
          taskbarTabListByTabEntityKey.value[taskbarEntityKey],
        )
      ) {
        return existingTaskbarTab
      }

      return taskbarTabListByTabEntityKey.value[taskbarEntityKey]
    },
  )
  const currentTaskbarTabEntityAccess = computed(
    () => currentTaskbarTab.value?.entityAccess,
  )

  const currentTaskbarTabId = computed(
    () => currentTaskbarTab.value?.taskbarTabId,
  )

  const currentTaskbarTabFormId = computed(
    () => currentTaskbarTab.value?.formId || undefined,
  )

  const currentTaskbarTabNewArticlePresent = computed(
    () => !!currentTaskbarTab.value?.formNewArticlePresent,
  )

  return {
    currentTaskbarTab,
    currentTaskbarTabEntityAccess,
    currentTaskbarTabId,
    currentTaskbarTabFormId,
    currentTaskbarTabNewArticlePresent,
  }
}

export const provideCurrentTaskbarTab = (data: CurrentTaskbarTabData) => {
  provide(CURRENT_TASKBAR_TAB_KEY, data)
}

export const useTaskbarTab = (context?: Ref<TaskbarTabContext>) => {
  const { taskbarTabContexts } = storeToRefs(useUserCurrentTaskbarTabsStore())

  const {
    currentTaskbarTab,
    currentTaskbarTabId,
    currentTaskbarTabFormId,
    currentTaskbarEntityKey,
    currentTaskbarTabNewArticlePresent,
  } = inject(CURRENT_TASKBAR_TAB_KEY) as CurrentTaskbarTabData

  const { updateTaskbarTab, deleteTaskbarTab } =
    useUserCurrentTaskbarTabsStore()

  // Keep track of the passed context and update the store state accordingly.
  if (context) {
    watch(
      context,
      (newValue) => {
        if (!currentTaskbarTab.value?.tabEntityKey) return

        taskbarTabContexts.value[currentTaskbarTab.value.tabEntityKey] =
          newValue
      },
      { immediate: true },
    )
  }

  const currentTaskbarTabUpdate = (
    taskbarTab: UserTaskbarTab,
    state?: Record<string, unknown>,
  ) => {
    if (!currentTaskbarTabId.value) return

    updateTaskbarTab(currentTaskbarTabId.value, taskbarTab, state)
  }

  watch(
    () =>
      currentTaskbarTab.value &&
      taskbarTabContexts.value[currentTaskbarTab.value.tabEntityKey]
        ?.formIsDirty,
    (isDirty) => {
      if (isDirty === undefined || !currentTaskbarTab.value) return

      if (currentTaskbarTab.value.dirty === isDirty) return

      currentTaskbarTabUpdate({
        ...currentTaskbarTab.value,
        dirty: isDirty,
      })
    },
  )

  const currentTaskbarTabDelete = () => {
    if (!currentTaskbarTabId.value) return

    deleteTaskbarTab(currentTaskbarTabId.value)
  }

  return {
    currentTaskbarTab,
    currentTaskbarEntityKey,
    currentTaskbarTabId,
    currentTaskbarTabFormId,
    currentTaskbarTabNewArticlePresent,
    currentTaskbarTabUpdate,
    currentTaskbarTabDelete,
  }
}
