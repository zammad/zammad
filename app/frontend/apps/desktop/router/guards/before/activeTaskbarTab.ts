// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { EnumTaskbarEntity } from '#shared/graphql/types.ts'
import log from '#shared/utils/log.ts'

import { useUserCurrentTaskbarTabsStore } from '#desktop/entities/user/current/stores/taskbarTabs.ts'

import type { NavigationGuard, RouteLocationNormalized } from 'vue-router'

const activeTaskbarTab: NavigationGuard = async (to: RouteLocationNormalized) => {
  if (
    !to.meta?.taskbarTabEntity ||
    (typeof to.meta.isTaskbarTabPossible === 'function' && !to.meta.isTaskbarTabPossible(to))
  ) {
    // Reset the previously active tab state if the new route does not support the taskbar.
    //   This needs to be handled here, since the activation of the next tab state happens below in the same guard,
    //   and it may get overwritten if it's executed from a separate place (e.g. a component lifecycle method).
    if (to.meta?.requiresAuth) useUserCurrentTaskbarTabsStore().resetActiveTaskbarTab()

    return true
  }

  const taskbarTabStore = useUserCurrentTaskbarTabsStore()

  const taskbarTabEntityType = to.meta.taskbarTabEntity as EnumTaskbarEntity

  const taskbarTypePlugin = taskbarTabStore.getTaskbarTabTypePlugin(taskbarTabEntityType)

  const taskbarTabEntityKey = taskbarTypePlugin.buildEntityTabKey(to)

  // TODO: instead of that I would only load the single item so that the page can already start working?
  if (taskbarTabStore.loading) await taskbarTabStore.waitForTaskbarListLoaded()

  // Not awaited, so the page opens without waiting for the taskbar. A failure is already reported by
  //   the mutation handler, and would otherwise go uncaught, e.g. when a reload aborts the request.
  taskbarTabStore.upsertTaskbarTab(taskbarTabEntityType, taskbarTabEntityKey, to).catch(() => {})

  // Remember the entity key for the current taskbar tab,
  //   so it can be used for checking the entity access.
  to.meta.taskbarTabEntityKey = taskbarTabEntityKey

  log.debug(
    `Route guard for '${to.path}': active taskbar tab with entity key '${taskbarTabEntityKey}'.`,
  )

  return true
}

export default activeTaskbarTab
