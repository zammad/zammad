// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { toRef } from 'vue'
import { useRouter } from 'vue-router'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'

import { useUserCurrentTaskbarTabsStore } from '#desktop/entities/user/current/stores/taskbarTabs.ts'

import type { UserTaskbarTab, UserTaskbarTabPlugin } from './types.ts'

export const useTaskbarTabRemove = () => {
  const taskbarTabStore = useUserCurrentTaskbarTabsStore()
  const { deleteTaskbarTab } = taskbarTabStore
  const activeTaskbarTabEntityKey = toRef(taskbarTabStore, 'activeTaskbarTabEntityKey')

  const router = useRouter()

  const removeTaskbarTab = async (
    taskbarTab: UserTaskbarTab,
    dirty?: boolean,
    plugin?: UserTaskbarTabPlugin,
  ) => {
    if (!taskbarTab.taskbarTabId) return

    if (plugin?.confirmTabRemove) {
      // Redirect to the taskbar tab that is to be closed, if:
      //   * it has a dirty state
      //   * it's not the currently active tab
      //   * the tab link can be computed
      if (
        dirty &&
        taskbarTab.tabEntityKey !== activeTaskbarTabEntityKey.value &&
        typeof plugin.buildTaskbarTabLink === 'function'
      ) {
        const link = plugin.buildTaskbarTabLink(taskbarTab.entity, taskbarTab.tabEntityKey)
        if (link) await router.push(link)
      }

      if (dirty) {
        const { waitForVariantConfirmation } = useConfirmation()
        const confirmed = await waitForVariantConfirmation(
          'unsaved',
          undefined,
          `ticket-unsaved-${taskbarTab.tabEntityKey}`,
        )

        if (!confirmed) return
      }
    }

    // The store will handle redirection to a historical route.
    deleteTaskbarTab(taskbarTab.taskbarTabId)
  }

  return { removeTaskbarTab }
}
