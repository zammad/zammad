// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { tryOnScopeDispose } from '@vueuse/shared'
import { keyBy } from 'lodash-es'
import { acceptHMRUpdate, defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'

import {
  EnumTaskbarApp,
  EnumTaskbarEntity,
  type UserCurrentTaskbarItemListQuery,
  type UserCurrentTaskbarItemUpdatesSubscription,
  type UserCurrentTaskbarItemUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { getApolloClient } from '#shared/server/apollo/client.ts'
import {
  MutationHandler,
  QueryHandler,
} from '#shared/server/apollo/handler/index.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type { ObjectWithId } from '#shared/types/utils.ts'
import log from '#shared/utils/log.ts'

import { userTaskbarTabPluginByType } from '#desktop/components/UserTaskbarTabs/plugins/index.ts'
import type { UserTaskbarTab } from '#desktop/components/UserTaskbarTabs/types.ts'

import { useUserCurrentTaskbarItemAddMutation } from '../graphql/mutations/userCurrentTaskbarItemAdd.api.ts'
import { useUserCurrentTaskbarItemDeleteMutation } from '../graphql/mutations/userCurrentTaskbarItemDelete.api.ts'
import { useUserCurrentTaskbarItemUpdateMutation } from '../graphql/mutations/userCurrentTaskbarItemUpdate.api.ts'
import {
  UserCurrentTaskbarItemListDocument,
  useUserCurrentTaskbarItemListQuery,
} from '../graphql/queries/userCurrentTaskbarItemList.api.ts'
import { UserCurrentTaskbarItemUpdatesDocument } from '../graphql/subscriptions/userCurrentTaskbarItemUpdates.api.ts'

import type { TaskbarTabContext } from '../types.ts'

export const useUserCurrentTaskbarTabsStore = defineStore(
  'userCurrentTaskbarTabs',
  () => {
    const session = useSessionStore()
    const router = useRouter()

    const activeTaskbarTabEntityKey = ref<string>()
    const activeTaskbarTabContext = ref<TaskbarTabContext>({})
    const taskbarTabsInCreation = ref<UserTaskbarTab[]>([])
    const taskbarTabIDsInDeletion = ref<ID[]>([])

    const getTaskbarTabTypePlugin = (tabEntityType: EnumTaskbarEntity) =>
      userTaskbarTabPluginByType[tabEntityType]

    const handleActiveTaskbarTabRemoval = (
      taskbarTabList: UserCurrentTaskbarItemListQuery['userCurrentTaskbarItemList'],
      removedItemId: string,
    ) => {
      const removedItem = taskbarTabList?.find(
        (tab) => tab.id === removedItemId,
      )

      if (!removedItem) return

      const removedItemPlugin = getTaskbarTabTypePlugin(removedItem.callback)
      if (typeof removedItemPlugin.buildTaskbarTabLink !== 'function') return

      const removedItemLink = removedItemPlugin.buildTaskbarTabLink(
        removedItem.entity,
      )
      if (!removedItemLink) return

      const removedItemRoute = router.resolve(removedItemLink)

      if (
        !removedItemRoute?.name ||
        router.currentRoute.value.name !== removedItemRoute.name
      )
        return

      // If the active taskbar tab was removed, redirect to the default route.
      //   TODO: Clarify and define the default or contextual route.
      router.push('/dashboard')
    }

    const taskbarTabsQuery = new QueryHandler(
      useUserCurrentTaskbarItemListQuery({ app: EnumTaskbarApp.Desktop }),
    )

    taskbarTabsQuery.subscribeToMore<
      UserCurrentTaskbarItemUpdatesSubscriptionVariables,
      UserCurrentTaskbarItemUpdatesSubscription
    >({
      document: UserCurrentTaskbarItemUpdatesDocument,
      variables: {
        app: EnumTaskbarApp.Desktop,
        userId: session.userId,
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

    const taskbarTabsRaw = taskbarTabsQuery.result()
    const taskbarTabsLoading = taskbarTabsQuery.loading()

    const taskbarTabList = computed<UserTaskbarTab[]>(() => {
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
              lastContact: taskbarTab.lastContact,
              order: taskbarTab.prio,
              formId: taskbarTab.formId,
              dirty: taskbarTab.dirty,
            }
          })

      const existingTabEntityKeys = new Set(
        taskbarTabs.map((taskbarTab) => taskbarTab.tabEntityKey),
      )

      return taskbarTabs
        .concat(
          taskbarTabsInCreation.value.filter(
            (taskbarTab) => !existingTabEntityKeys.has(taskbarTab.tabEntityKey),
          ),
        )
        .sort((a, b) => a.order - b.order)
    })

    const activeTaskbarTab = computed<UserTaskbarTab | undefined>(() => {
      if (!activeTaskbarTabEntityKey.value) return

      return taskbarTabList.value.find(
        (taskbarTab) =>
          taskbarTab.tabEntityKey === activeTaskbarTabEntityKey.value,
      )
    })

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

    const addTaskbarTab = (
      taskbarTabEntity: EnumTaskbarEntity,
      tabEntityKey: string,
      tabEntityInternalId: string,
    ) => {
      const { buildTaskbarTabParams, entityType, entityDocument } =
        getTaskbarTabTypePlugin(taskbarTabEntity)

      const order = hasTaskbarTabs.value
        ? taskbarTabList.value[taskbarTabList.value.length - 1].order + 1
        : 1

      // Add temporary in creation taskbar tab item when we have already an existing entity from the cache.
      if (entityType && entityDocument) {
        const cachedEntity = getApolloClient().cache.readFragment<ObjectWithId>(
          {
            id: `${entityType}:${convertToGraphQLId(
              entityType,
              tabEntityInternalId,
            )}`,
            fragment: entityDocument,
          },
        )

        if (cachedEntity) {
          taskbarTabsInCreation.value.push({
            type: taskbarTabEntity,
            entity: cachedEntity,
            tabEntityKey,
            lastContact: new Date().toISOString(),
            order,
          })
        }
      }

      taskbarAddMutation
        .send({
          input: {
            app: EnumTaskbarApp.Desktop,
            callback: taskbarTabEntity,
            key: tabEntityKey,
            notify: false, // TODO: check use case? maybe we can remove it.
            params: buildTaskbarTabParams(tabEntityInternalId),
            prio: order,
          },
        })
        .finally(() => {
          // Remove temporary in creation taskar tab again.
          taskbarTabsInCreation.value = taskbarTabsInCreation.value.filter(
            (tab) => tab.tabEntityKey !== tabEntityKey,
          )
        })
    }

    const taskbarUpdateMutation = new MutationHandler(
      useUserCurrentTaskbarItemUpdateMutation({
        update: (cache, { data }) => {
          if (!data) return

          const { userCurrentTaskbarItemUpdate } = data
          if (!userCurrentTaskbarItemUpdate?.taskbarItem) return

          const existingTaskbarItemList =
            cache.readQuery<UserCurrentTaskbarItemListQuery>({
              query: UserCurrentTaskbarItemListDocument,
            })

          const listIndex =
            existingTaskbarItemList?.userCurrentTaskbarItemList?.findIndex(
              (taskbarTab) =>
                taskbarTab.id === userCurrentTaskbarItemUpdate?.taskbarItem?.id,
            )

          if (!listIndex) return

          existingTaskbarItemList?.userCurrentTaskbarItemList?.splice(
            listIndex,
            1,
            userCurrentTaskbarItemUpdate?.taskbarItem,
          )

          cache.writeQuery({
            query: UserCurrentTaskbarItemListDocument,
            data: existingTaskbarItemList,
          })
        },
      }),
    )

    const updateTaskbarTab = (taskbarTabId: ID, taskbarTab: UserTaskbarTab) => {
      const { buildTaskbarTabParams } = getTaskbarTabTypePlugin(taskbarTab.type)

      taskbarUpdateMutation.send({
        id: taskbarTabId,
        input: {
          app: EnumTaskbarApp.Desktop,
          callback: taskbarTab.type,
          key: taskbarTab.tabEntityKey,
          notify: false, // TODO: check use case? maybe we can remove it.
          params: buildTaskbarTabParams(taskbarTab.tabEntityKey),
          prio: taskbarTab.order,
          dirty: taskbarTab.dirty,
        },
      })
    }

    const upsertTaskbarTab = (
      taskbarTabEntity: EnumTaskbarEntity,
      tabEntityKey: string,
      tabEntityInternalId: string,
    ) => {
      activeTaskbarTabEntityKey.value = tabEntityKey

      if (!taskbarTabExists(taskbarTabEntity, tabEntityKey)) {
        addTaskbarTab(taskbarTabEntity, tabEntityKey, tabEntityInternalId)
        return
      }

      // TODO: Do something for existing tabs here???
      console.log('HERE-SOMETHING-FOR-EXISTING-TABS')
    }

    // TODO: Do we need to handle anything else?!

    const taskbarDeleteMutation = new MutationHandler(
      useUserCurrentTaskbarItemDeleteMutation(),
    )
    const deleteTaskbarTab = (taskbarTabId: ID) => {
      taskbarTabIDsInDeletion.value.push(taskbarTabId)

      taskbarDeleteMutation
        .send({
          id: taskbarTabId,
        })
        .catch((error) => {
          taskbarTabIDsInDeletion.value = taskbarTabIDsInDeletion.value.filter(
            (inDeletionTaskbarTabId) => inDeletionTaskbarTabId !== taskbarTabId,
          )
          // TODO: Toast message or more the notifcaiotn error message needs to be added?
          log.error('Failed to delete taskbar tab.', error)
        })
    }

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
      activeTaskbarTab,
      activeTaskbarTabEntityKey,
      activeTaskbarTabContext,
      taskbarTabsInCreation,
      taskbarTabsRaw,
      taskbarTabList,
      taskbarTabListByTabEntityKey,
      taskbarTabListOrder,
      taskbarTabExists,
      getTaskbarTabTypePlugin,
      addTaskbarTab,
      updateTaskbarTab,
      upsertTaskbarTab,
      deleteTaskbarTab,
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
