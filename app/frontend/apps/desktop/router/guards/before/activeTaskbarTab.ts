// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { EnumTaskbarEntity } from '#shared/graphql/types.ts'
import log from '#shared/utils/log.ts'

import { useUserCurrentTaskbarTabsStore } from '#desktop/entities/user/current/stores/taskbarTabs.ts'

import type {
  NavigationGuard,
  RouteLocationNormalized,
  NavigationGuardNext,
} from 'vue-router'

const activeTaskbarTab: NavigationGuard = async (
  to: RouteLocationNormalized,
  from: RouteLocationNormalized,
  next: NavigationGuardNext,
) => {
  if (
    !to.meta?.taskbarTabEntity ||
    (!to.params.internalId && !to.params.tabId)
  ) {
    if (to.meta?.requiresAuth) {
      // Reset the previously active tab state if the new route does not support the taskbar.
      //   This needs to be handled here, since the activation of the next tab state happens below in the same guard,
      //   and it may get overwritten if it's executed from a separate place (e.g. a component lifecycle method).
      useUserCurrentTaskbarTabsStore().resetActiveTaskbarTab()
    }

    next()

    return
  }

  const taskbarTabStore = useUserCurrentTaskbarTabsStore()

  const taskbarTabEntityType = to.meta.taskbarTabEntity as EnumTaskbarEntity

  const taskbarTypePlugin =
    taskbarTabStore.getTaskbarTabTypePlugin(taskbarTabEntityType)

  const tabEntityInternalId = (to.params.internalId ||
    to.params.tabId) as string

  const taskbarTabEntityKey =
    taskbarTypePlugin.buildEntityTabKey(tabEntityInternalId)

  // TODO: instead of that I would only load the single item so that the page can already start working?
  if (taskbarTabStore.loading) {
    await taskbarTabStore.waitForTaskbarListLoaded()
  }

  await taskbarTabStore.upsertTaskbarTab(
    taskbarTabEntityType,
    taskbarTabEntityKey,
    tabEntityInternalId,
  )

  // Remember the entity key for the current taskbar tab,
  //   so it can be used for checking the entity access.
  to.meta.taskbarTabEntityKey = taskbarTabEntityKey

  log.debug(
    `Route guard for '${to.path}': active taskbar tab with entity key '${taskbarTabEntityKey}'.`,
  )

  next()
}

export default activeTaskbarTab
