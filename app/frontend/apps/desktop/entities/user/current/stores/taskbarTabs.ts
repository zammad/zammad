// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { tryOnScopeDispose } from '@vueuse/shared'
import { isEqual, keyBy } from 'lodash-es'
import { acceptHMRUpdate, defineStore } from 'pinia'
import { computed, ref, watch } from 'vue'
import { useRouter, type RouteLocationNormalizedGeneric } from 'vue-router'

import {
  EnumTaskbarApp,
  EnumTaskbarEntity,
  type TaskbarItemEntity,
  type UserCurrentTaskbarItemListQuery,
  type UserCurrentTaskbarItemListUpdatesSubscription,
  type UserCurrentTaskbarItemListUpdatesSubscriptionVariables,
  type UserCurrentTaskbarItemUpdatesSubscription,
  type UserCurrentTaskbarItemUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { getApolloClient } from '#shared/server/apollo/client.ts'
import {
  MutationHandler,
  QueryHandler,
} from '#shared/server/apollo/handler/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import log from '#shared/utils/log.ts'

import { userTaskbarTabPluginByType } from '#desktop/components/UserTaskbarTabs/plugins/index.ts'
import type {
  BackRoute,
  UserTaskbarTab,
} from '#desktop/components/UserTaskbarTabs/types.ts'

import { useUserCurrentTaskbarItemAddMutation } from '../graphql/mutations/userCurrentTaskbarItemAdd.api.ts'
import { useUserCurrentTaskbarItemDeleteMutation } from '../graphql/mutations/userCurrentTaskbarItemDelete.api.ts'
import { useUserCurrentTaskbarItemTouchLastContactMutation } from '../graphql/mutations/userCurrentTaskbarItemTouchLastContact.api.ts'
import { useUserCurrentTaskbarItemUpdateMutation } from '../graphql/mutations/userCurrentTaskbarItemUpdate.api.ts'
import {
  UserCurrentTaskbarItemListDocument,
  useUserCurrentTaskbarItemListQuery,
} from '../graphql/queries/userCurrentTaskbarItemList.api.ts'
import { UserCurrentTaskbarItemListUpdatesDocument } from '../graphql/subscriptions/userCurrentTaskbarItemListUpdates.api.ts'
import { UserCurrentTaskbarItemUpdatesDocument } from '../graphql/subscriptions/userCurrentTaskbarItemUpdates.api.ts'

import type { TaskbarTabContext } from '../types.ts'

export const useUserCurrentTaskbarTabsStore = defineStore(
  'userCurrentTaskbarTabs',
  () => {
    const application = useApplicationStore()
    const router = useRouter()

    const taskbarTabContexts = ref<Record<string, TaskbarTabContext>>({})

    const activeTaskbarTabEntityKey = ref<string>()
    const taskbarTabsInCreation = ref<UserTaskbarTab[]>([])
    const taskbarTabIDsInDeletion = ref<ID[]>([])

    const getTaskbarTabTypePlugin = (tabEntityType: EnumTaskbarEntity) =>
      userTaskbarTabPluginByType[tabEntityType]

    const taskbarTabsQuery = new QueryHandler(
      useUserCurrentTaskbarItemListQuery(
        { app: EnumTaskbarApp.Desktop },
        {
          context: {
            batch: {
              active: false,
            },
          },
        },
      ),
    )

    const taskbarTabsRaw = taskbarTabsQuery.result()
    const taskbarTabsLoading = taskbarTabsQuery.loading()

    const taskbarTabList = computed<UserTaskbarTab[]>(
      (currentTaskbarTabList) => {
        if (!taskbarTabsRaw.value?.userCurrentTaskbarItemList) return []

        const taskbarTabs: UserTaskbarTab[] =
          taskbarTabsRaw.value.userCurrentTaskbarItemList
            .filter(
              (taskbarTab) =>
                !taskbarTabIDsInDeletion.value.includes(taskbarTab.id),
            )
            .flatMap((taskbarTab) => {
              const type = taskbarTab.callback

              if (!userTaskbarTabPluginByType[type]) {
                log.warn(`Unknown taskbar tab type: ${type}.`)
                return []
              }

              return {
                type,
                entity: taskbarTab.entity,
                entityAccess: taskbarTab.entityAccess,
                tabEntityKey: taskbarTab.key,
                taskbarTabId: taskbarTab.id,
                order: taskbarTab.prio,
                formId: taskbarTab.formId,
                formNewArticlePresent: taskbarTab.formNewArticlePresent,
                changed: taskbarTab.changed,
                dirty: taskbarTab.dirty,
                notify: taskbarTab.notify,
                updatedAt: taskbarTab.updatedAt,
              } as UserTaskbarTab
            })

        const existingTabEntityKeys = new Set(
          taskbarTabs.map((taskbarTab) => taskbarTab.tabEntityKey),
        )

        const newTaskbarTabList = taskbarTabs
          .concat(
            taskbarTabsInCreation.value.filter(
              (taskbarTab) =>
                !existingTabEntityKeys.has(taskbarTab.tabEntityKey),
            ),
          )
          .sort((a, b) => a.order - b.order)

        if (
          currentTaskbarTabList &&
          isEqual(currentTaskbarTabList, newTaskbarTabList)
        )
          return currentTaskbarTabList

        return newTaskbarTabList
      },
    )

    const activeTaskbarTab = computed<UserTaskbarTab | undefined>(
      (currentActiveTaskbarTab) => {
        if (!activeTaskbarTabEntityKey.value) return

        const newActiveTaskbarTab = taskbarTabList.value.find(
          (taskbarTab) =>
            taskbarTab.tabEntityKey === activeTaskbarTabEntityKey.value,
        )

        if (
          currentActiveTaskbarTab &&
          isEqual(newActiveTaskbarTab, currentActiveTaskbarTab)
        )
          return currentActiveTaskbarTab

        return newActiveTaskbarTab
      },
    )

    const activeTaskbarTabId = computed(
      () => activeTaskbarTab.value?.taskbarTabId,
    )

    const activeTaskbarTabEntityAccess = computed(
      () => activeTaskbarTab.value?.entityAccess,
    )

    const hasTaskbarTabs = computed(() => taskbarTabList.value?.length > 0)

    const taskbarTabListByTabEntityKey = computed(() =>
      keyBy(taskbarTabList.value, 'tabEntityKey'),
    )

    const taskbarTabListOrder = computed(() =>
      taskbarTabList.value.reduce((taskbarTabListOrder, taskbarTab) => {
        taskbarTabListOrder.push(taskbarTab.tabEntityKey)
        return taskbarTabListOrder
      }, [] as string[]),
    )

    const taskbarLookupByTypeAndTabEntityKey = computed(() => {
      return taskbarTabList.value.reduce(
        (lookup, tab) => {
          if (!tab.taskbarTabId) return lookup

          lookup[tab.type] = lookup[tab.type] || {}
          lookup[tab.type][tab.tabEntityKey] = tab.taskbarTabId

          return lookup
        },
        {} as Record<EnumTaskbarEntity, Record<ID, ID>>,
      )
    })

    const taskbarTabExists = (type: EnumTaskbarEntity, tabEntityKey: string) =>
      Boolean(taskbarLookupByTypeAndTabEntityKey.value[type]?.[tabEntityKey])

    const previousRoutes = ref<BackRoute[]>([])

    // Keep track of previously visited routes and if they are taskbar tab routes.
    router.afterEach((_, from) => {
      // Clear all previous routes whenever a non-taskbar tab route is visited.
      if (!from.meta?.taskbarTabEntityKey) previousRoutes.value.length = 0

      previousRoutes.value.push({
        path: from.fullPath,
        taskbarTabEntityKey: from.meta?.taskbarTabEntityKey,
      })
    })

    const backRoutes = computed(() => [...previousRoutes.value].reverse())

    const redirectToLastHistoricalRoute = () => {
      // In case of taskbar tab routes, make sure the tab is still present in the list.
      //   We can do this by comparing the historical taskbar tab entity key against the current tab list.
      const nextRoute = backRoutes.value.find((backRoute) => {
        // Return a non-taskbar tab route immediately.
        if (!backRoute.taskbarTabEntityKey) return true

        // Ignore the current tab, we will be closing it shortly.
        if (backRoute.taskbarTabEntityKey === activeTaskbarTabEntityKey.value)
          return false

        // Check if the taskbar tab route is part of the current taskbar.
        return !!taskbarTabListByTabEntityKey.value[
          backRoute.taskbarTabEntityKey
        ]
      })

      // If identified, redirect to the historical route.
      if (nextRoute) {
        router.push(nextRoute.path)
        return
      }

      // Otherwise, redirect to the fallback route.
      //   TODO: Adjust the following redirect fallback to Overviews page instead, when ready.
      router.push('/')
    }

    const handleActiveTaskbarTabRemoval = (
      taskbarTabList: UserCurrentTaskbarItemListQuery['userCurrentTaskbarItemList'],
      removedItemId: string,
    ) => {
      const removedItem = taskbarTabList?.find(
        (tab) => tab.id === removedItemId,
      )

      if (!removedItem) return
      if (removedItem.key !== activeTaskbarTabEntityKey.value) return

      // If the active taskbar tab was removed, redirect to the last historical route.
      redirectToLastHistoricalRoute()
    }

    taskbarTabsQuery.subscribeToMore<
      UserCurrentTaskbarItemUpdatesSubscriptionVariables,
      UserCurrentTaskbarItemUpdatesSubscription
    >({
      document: UserCurrentTaskbarItemUpdatesDocument,
      variables: {
        app: EnumTaskbarApp.Desktop,
      },
      updateQuery(previous, { subscriptionData }) {
        const updates = subscriptionData.data.userCurrentTaskbarItemUpdates

        if (!updates.addItem && !updates.updateItem && !updates.removeItem)
          return null as unknown as UserCurrentTaskbarItemListQuery

        if (!previous.userCurrentTaskbarItemList || updates.updateItem)
          return previous

        const previousTaskbarTabList = previous.userCurrentTaskbarItemList

        if (updates.removeItem) {
          const newTaskbarTabList = previousTaskbarTabList.filter(
            (tab) => tab.id !== updates.removeItem,
          )

          handleActiveTaskbarTabRemoval(
            previousTaskbarTabList,
            updates.removeItem,
          )

          return {
            userCurrentTaskbarItemList: newTaskbarTabList,
          }
        }

        if (updates.addItem) {
          const newIdPresent = previousTaskbarTabList.find((taskbarTab) => {
            return taskbarTab.id === updates.addItem?.id
          })

          if (newIdPresent) return previous

          return {
            userCurrentTaskbarItemList: [
              ...previousTaskbarTabList,
              updates.addItem,
            ],
          }
        }

        return previous
      },
    })

    taskbarTabsQuery.subscribeToMore<
      UserCurrentTaskbarItemListUpdatesSubscriptionVariables,
      UserCurrentTaskbarItemListUpdatesSubscription
    >({
      document: UserCurrentTaskbarItemListUpdatesDocument,
      variables: {
        app: EnumTaskbarApp.Desktop,
      },
    })

    const taskbarAddMutation = new MutationHandler(
      useUserCurrentTaskbarItemAddMutation({
        update: (cache, { data }) => {
          if (!data) return

          const { userCurrentTaskbarItemAdd } = data
          if (!userCurrentTaskbarItemAdd?.taskbarItem) return

          const newIdPresent = taskbarTabList.value.find((taskbarTab) => {
            return (
              taskbarTab.taskbarTabId ===
              userCurrentTaskbarItemAdd.taskbarItem?.id
            )
          })
          if (newIdPresent) return

          let existingTaskbarItemList =
            cache.readQuery<UserCurrentTaskbarItemListQuery>({
              query: UserCurrentTaskbarItemListDocument,
            })

          existingTaskbarItemList = {
            ...existingTaskbarItemList,
            userCurrentTaskbarItemList: [
              ...(existingTaskbarItemList?.userCurrentTaskbarItemList || []),
              userCurrentTaskbarItemAdd.taskbarItem,
            ],
          }

          cache.writeQuery({
            query: UserCurrentTaskbarItemListDocument,
            data: existingTaskbarItemList,
          })
        },
      }),
    )

    const addTaskbarTab = async (
      taskbarTabEntity: EnumTaskbarEntity,
      tabEntityKey: string,
      route: RouteLocationNormalizedGeneric,
    ) => {
      const {
        buildTaskbarTabEntityId,
        buildTaskbarTabParams,
        entityType,
        entityDocument,
      } = getTaskbarTabTypePlugin(taskbarTabEntity)

      const order = hasTaskbarTabs.value
        ? taskbarTabList.value[taskbarTabList.value.length - 1].order + 1
        : 1

      // Add temporary in creation taskbar tab item when we have already an existing entity from the cache.
      if (entityType && entityDocument) {
        const tabEntityInternalId = buildTaskbarTabEntityId(route)

        if (tabEntityInternalId) {
          const cachedEntity =
            getApolloClient().cache.readFragment<TaskbarItemEntity>({
              id: `${entityType}:${convertToGraphQLId(
                entityType,
                tabEntityInternalId,
              )}`,
              fragment: entityDocument,
            })

          if (cachedEntity) {
            taskbarTabsInCreation.value.push({
              type: taskbarTabEntity,
              entity: cachedEntity,
              tabEntityKey,
              order,
            })
          }
        }
      }

      await taskbarAddMutation
        .send({
          input: {
            app: EnumTaskbarApp.Desktop,
            callback: taskbarTabEntity,
            key: tabEntityKey,
            notify: false,
            params: buildTaskbarTabParams(route),
            prio: order,
          },
        })
        .finally(() => {
          // Remove temporary in creation taskbar tab again.
          taskbarTabsInCreation.value = taskbarTabsInCreation.value.filter(
            (tab) => tab.tabEntityKey !== tabEntityKey,
          )
        })
    }

    const taskbarUpdateMutation = new MutationHandler(
      useUserCurrentTaskbarItemUpdateMutation(),
    )

    const updateTaskbarTab = (
      taskbarTabId: ID,
      taskbarTab: UserTaskbarTab,
      state?: Record<string, unknown>,
    ) => {
      taskbarUpdateMutation.send({
        id: taskbarTabId,
        input: {
          app: EnumTaskbarApp.Desktop,
          callback: taskbarTab.type,
          key: taskbarTab.tabEntityKey,
          notify: !!taskbarTab.notify,
          state,
          prio: taskbarTab.order,
          dirty: taskbarTab.dirty,
        },
      })
    }

    const taskbarTouchMutation = new MutationHandler(
      useUserCurrentTaskbarItemTouchLastContactMutation(),
    )

    const touchTaskbarTab = async (taskbarTabId: ID) => {
      await taskbarTouchMutation.send({
        id: taskbarTabId,
      })
    }

    const upsertTaskbarTab = async (
      taskbarTabEntity: EnumTaskbarEntity,
      tabEntityKey: string,
      route: RouteLocationNormalizedGeneric,
    ) => {
      activeTaskbarTabEntityKey.value = tabEntityKey

      if (!taskbarTabExists(taskbarTabEntity, tabEntityKey)) {
        await addTaskbarTab(taskbarTabEntity, tabEntityKey, route)
        return
      }

      const taskbarTab = taskbarTabListByTabEntityKey.value[tabEntityKey]
      if (!taskbarTab || !taskbarTab.taskbarTabId) return

      const { touchExistingTab } = getTaskbarTabTypePlugin(taskbarTabEntity)
      if (!touchExistingTab) return

      await touchTaskbarTab(taskbarTab.taskbarTabId)
    }

    const resetActiveTaskbarTab = () => {
      if (!activeTaskbarTabEntityKey.value) return

      activeTaskbarTabEntityKey.value = undefined
    }

    let silenceTaskbarDeleteError = false

    const taskbarDeleteMutation = new MutationHandler(
      useUserCurrentTaskbarItemDeleteMutation(),
      {
        errorCallback: () => {
          if (silenceTaskbarDeleteError) return false
        },
      },
    )

    const deleteTaskbarTab = (taskbarTabId: ID, silenceError?: boolean) => {
      taskbarTabIDsInDeletion.value.push(taskbarTabId)

      if (silenceError) silenceTaskbarDeleteError = true

      taskbarDeleteMutation
        .send({
          id: taskbarTabId,
        })
        .catch(() => {
          taskbarTabIDsInDeletion.value = taskbarTabIDsInDeletion.value.filter(
            (inDeletionTaskbarTabId) => inDeletionTaskbarTabId !== taskbarTabId,
          )
        })
        .finally(() => {
          if (silenceError) silenceTaskbarDeleteError = false
        })
    }

    watch(taskbarTabList, (newTaskbarTabList) => {
      if (
        !newTaskbarTabList ||
        newTaskbarTabList.length <=
          application.config.ui_task_mananger_max_task_count
      )
        return

      const sortedTaskbarTabList = newTaskbarTabList
        .filter(
          (taskbarTab) =>
            taskbarTab.taskbarTabId !== activeTaskbarTab.value?.taskbarTabId &&
            taskbarTab.updatedAt &&
            !taskbarTab.changed &&
            !taskbarTab.dirty,
        )
        .sort(
          (a, b) =>
            new Date(a.updatedAt!).getTime() - new Date(b.updatedAt!).getTime(),
        )

      if (!sortedTaskbarTabList.length) return

      const oldestTaskbarTab = sortedTaskbarTabList.at(0)
      if (!oldestTaskbarTab?.taskbarTabId) return

      log.info(
        `More than the allowed maximum number of tasks are open (${application.config.ui_task_mananger_max_task_count}), closing the oldest untouched task now.`,
        oldestTaskbarTab.tabEntityKey,
      )

      deleteTaskbarTab(oldestTaskbarTab.taskbarTabId, true)
    })

    const waitForTaskbarListLoaded = () => {
      return new Promise<void>((resolve) => {
        const interval = setInterval(() => {
          if (taskbarTabsLoading.value) return

          clearInterval(interval)
          resolve()
        })
      })
    }

    tryOnScopeDispose(() => {
      taskbarTabsQuery.stop()
    })

    return {
      taskbarTabIDsInDeletion,
      activeTaskbarTabId,
      activeTaskbarTab,
      activeTaskbarTabEntityKey,
      activeTaskbarTabEntityAccess,
      taskbarTabContexts,
      taskbarTabsInCreation,
      taskbarTabsRaw,
      taskbarTabList,
      taskbarTabListByTabEntityKey,
      taskbarLookupByTypeAndTabEntityKey,
      taskbarTabListOrder,
      taskbarTabExists,
      getTaskbarTabTypePlugin,
      addTaskbarTab,
      updateTaskbarTab,
      upsertTaskbarTab,
      deleteTaskbarTab,
      resetActiveTaskbarTab,
      waitForTaskbarListLoaded,
      loading: taskbarTabsLoading,
      hasTaskbarTabs,
    }
  },
)

if (import.meta.hot) {
  import.meta.hot.accept(
    acceptHMRUpdate(useUserCurrentTaskbarTabsStore, import.meta.hot),
  )
}
