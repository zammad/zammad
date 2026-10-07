// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ApolloLink, Observable, type FetchResult } from '@apollo/client/core'
import { createPinia, setActivePinia } from 'pinia'

import { mockedApolloClient } from '#tests/graphql/builders/mocks.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { EnumTaskbarApp, EnumTaskbarEntity } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import { mockUserCurrentTaskbarItemAddMutation } from '#desktop/entities/user/current/graphql/mutations/userCurrentTaskbarItemAdd.mocks.ts'
import { mockUserCurrentTaskbarItemDeleteMutationError } from '#desktop/entities/user/current/graphql/mutations/userCurrentTaskbarItemDelete.mocks.ts'
import { waitForUserCurrentTaskbarItemTouchLastContactMutationCalls } from '#desktop/entities/user/current/graphql/mutations/userCurrentTaskbarItemTouchLastContact.mocks.ts'
import {
  mockUserCurrentTaskbarItemListQuery,
  waitForUserCurrentTaskbarItemListQueryCalls,
} from '#desktop/entities/user/current/graphql/queries/userCurrentTaskbarItemList.mocks.ts'

import { useUserCurrentTaskbarTabsStore } from '../taskbarTabs.ts'

import type { RouteLocationNormalizedGeneric } from 'vue-router'

vi.mock('vue-router', async () => {
  const module = await vi.importActual<typeof import('vue-router')>('vue-router')

  return {
    ...module,
    useRouter: () => ({ afterEach: vi.fn(), push: vi.fn() }),
  }
})

const taskbarItemId = (internalId: number) => convertToGraphQLId('Taskbar', internalId)

const taskbarItem = (
  internalId: number,
  options: { changed?: boolean; dirty?: boolean; updatedAt?: string } = {},
) => ({
  id: taskbarItemId(internalId),
  key: `Ticket-${internalId}`,
  callback: EnumTaskbarEntity.TicketZoom,
  app: EnumTaskbarApp.Desktop,
  prio: internalId,
  notify: false,
  changed: options.changed ?? false,
  dirty: options.dirty ?? false,
  updatedAt: options.updatedAt ?? `2026-09-${String(internalId).padStart(2, '0')}T10:00:00Z`,
  entity: null,
})

const newTaskbarItemInternalId = 9

const route = { params: { internalId: '9' } } as unknown as RouteLocationNormalizedGeneric

const setupStore = async (taskbarItems: ReturnType<typeof taskbarItem>[]) => {
  mockUserCurrentTaskbarItemListQuery({
    userCurrentTaskbarItemList: taskbarItems,
  })

  const store = useUserCurrentTaskbarTabsStore()

  await waitForUserCurrentTaskbarItemListQueryCalls()
  await waitForNextTick()

  return store
}

const addNewTaskbarTab = async (store: ReturnType<typeof useUserCurrentTaskbarTabsStore>) => {
  mockUserCurrentTaskbarItemAddMutation({
    userCurrentTaskbarItemAdd: {
      taskbarItem: taskbarItem(newTaskbarItemInternalId, { updatedAt: '2026-09-20T10:00:00Z' }),
      errors: null,
    },
  })

  await store.addTaskbarTab(
    EnumTaskbarEntity.TicketZoom,
    `Ticket-${newTaskbarItemInternalId}`,
    route,
  )
}

// Holds the deletion of one tab back until the returned function is called - what a slow response
//   looks like. The mocked link answers within the same tick otherwise, which leaves no deletion in
//   flight while another one settles.
const holdTaskbarTabDeletion = (internalId: number) => {
  const { link } = mockedApolloClient

  let release = () => {}
  const released = new Promise<void>((resolve) => {
    release = resolve
  })

  mockedApolloClient.setLink(
    new ApolloLink((operation, forward) => {
      if (
        operation.operationName !== 'userCurrentTaskbarItemDelete' ||
        operation.variables.id !== taskbarItemId(internalId)
      )
        return forward(operation)

      return new Observable<FetchResult>((observer) => {
        let subscription: { unsubscribe: () => void } | undefined

        released.then(() => {
          subscription = forward(operation).subscribe(observer)
        })

        return () => subscription?.unsubscribe()
      })
    }).concat(link),
  )

  onTestFinished(() => mockedApolloClient.setLink(link))

  return release
}

const failTaskbarTabDeletions = () =>
  mockUserCurrentTaskbarItemDeleteMutationError('Something went wrong', {
    type: GraphQLErrorTypes.UnknownError,
  })

describe('useUserCurrentTaskbarTabsStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())

    mockApplicationConfig({ ui_task_mananger_max_task_count: 3 })
  })

  describe('maximum number of open tabs', () => {
    it('closes the oldest untouched tab when a new tab exceeds the limit', async () => {
      const store = await setupStore([taskbarItem(1), taskbarItem(2), taskbarItem(3)])

      await addNewTaskbarTab(store)

      expect(store.taskbarTabIDsInDeletion).toEqual([taskbarItemId(1)])
    })

    it('closes as many tabs as the list is over the limit, oldest first', async () => {
      const store = await setupStore([
        taskbarItem(1),
        taskbarItem(2),
        taskbarItem(3),
        taskbarItem(4),
        taskbarItem(5),
      ])

      await addNewTaskbarTab(store)

      expect(store.taskbarTabIDsInDeletion).toEqual([
        taskbarItemId(1),
        taskbarItemId(2),
        taskbarItemId(3),
      ])
    })

    it('keeps tabs that are not older than the one just added', async () => {
      const store = await setupStore([
        taskbarItem(1, { changed: true }),
        taskbarItem(2, { changed: true }),
        taskbarItem(3),
        // Same age and younger than the added tab, as a tab another window has just added.
        taskbarItem(4, { updatedAt: '2026-09-20T10:00:00Z' }),
        taskbarItem(5, { updatedAt: '2026-09-20T10:00:01Z' }),
      ])

      await addNewTaskbarTab(store)

      expect(store.taskbarTabIDsInDeletion).toEqual([taskbarItemId(3)])
    })

    it('keeps the new tab and runs over the limit when no older tab can be closed', async () => {
      const store = await setupStore([
        taskbarItem(1, { changed: true }),
        taskbarItem(2, { changed: true }),
        taskbarItem(3, { dirty: true }),
      ])

      await addNewTaskbarTab(store)

      expect(store.taskbarTabIDsInDeletion).toEqual([])
      expect(store.taskbarTabList).toHaveLength(4)
    })

    it('never closes the active tab', async () => {
      const store = await setupStore([
        taskbarItem(1),
        taskbarItem(2, { changed: true }),
        taskbarItem(3, { changed: true }),
      ])

      store.activeTaskbarTabEntityKey = 'Ticket-1'

      await addNewTaskbarTab(store)

      expect(store.taskbarTabIDsInDeletion).toEqual([])
    })

    it('closes nothing when the maximum is 0', async () => {
      mockApplicationConfig({ ui_task_mananger_max_task_count: 0 })

      const store = await setupStore([taskbarItem(1), taskbarItem(2), taskbarItem(3)])

      await addNewTaskbarTab(store)

      expect(store.taskbarTabIDsInDeletion).toEqual([])
    })

    it('closes nothing when the list is already over the limit without a local add', async () => {
      const store = await setupStore([1, 2, 3, 4, 5].map((id) => taskbarItem(id)))

      await waitForNextTick()

      expect(store.taskbarTabIDsInDeletion).toEqual([])
    })

    it('closes nothing when an existing tab is only reopened', async () => {
      const store = await setupStore([
        taskbarItem(1),
        taskbarItem(2, { changed: true }),
        taskbarItem(3, { changed: true }),
        taskbarItem(4, { changed: true }),
      ])

      await store.upsertTaskbarTab(EnumTaskbarEntity.TicketZoom, 'Ticket-4', route)

      await waitForUserCurrentTaskbarItemTouchLastContactMutationCalls()

      expect(store.taskbarTabIDsInDeletion).toEqual([])
    })
  })

  describe('errors of tabs closed over the limit', () => {
    beforeEach(() => {
      useNotifications().clearAllNotifications()
    })

    it('stays silent when a tab closed over the limit fails after another one settled', async () => {
      const store = await setupStore([
        taskbarItem(1),
        taskbarItem(2),
        taskbarItem(3),
        taskbarItem(4),
      ])

      const releaseSecondDeletion = holdTaskbarTabDeletion(2)

      await addNewTaskbarTab(store)

      expect(store.taskbarTabIDsInDeletion).toEqual([taskbarItemId(1), taskbarItemId(2)])

      // The first deletion is answered within the same tick and has settled by now.
      await waitForNextTick(true)

      failTaskbarTabDeletions()
      releaseSecondDeletion()
      await waitForNextTick(true)

      expect(store.taskbarTabIDsInDeletion).toEqual([taskbarItemId(1)])
      expect(useNotifications().notifications.value).toHaveLength(0)
    })

    it('notifies when a tab the user closes fails while one closed over the limit is pending', async () => {
      failTaskbarTabDeletions()

      const store = await setupStore([taskbarItem(1), taskbarItem(2), taskbarItem(3)])

      const releaseFirstDeletion = holdTaskbarTabDeletion(1)

      await addNewTaskbarTab(store)

      store.deleteTaskbarTab(taskbarItemId(2))
      await waitForNextTick(true)

      expect(store.taskbarTabIDsInDeletion).toEqual([taskbarItemId(1)])
      expect(useNotifications().notifications.value).toMatchObject([
        { type: NotificationTypes.Error, message: 'An error occurred during the operation.' },
      ])

      releaseFirstDeletion()
      await waitForNextTick(true)

      expect(store.taskbarTabIDsInDeletion).toEqual([])
      expect(useNotifications().notifications.value).toHaveLength(1)
    })
  })
})
