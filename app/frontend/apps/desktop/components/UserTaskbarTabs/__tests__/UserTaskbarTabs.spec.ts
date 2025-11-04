// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { getByRole, waitFor } from '@testing-library/vue'
import { storeToRefs } from 'pinia'
import { type RouteRecordRaw } from 'vue-router'

import { getAllByIconName, getByIconName } from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import {
  EnumTaskbarEntity,
  EnumTaskbarEntityAccess,
  EnumTicketStateColorCode,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { waitForUserCurrentTaskbarItemDeleteMutationCalls } from '#desktop/entities/user/current/graphql/mutations/userCurrentTaskbarItemDelete.mocks.ts'
import {
  mockUserCurrentTaskbarItemListPrioMutation,
  waitForUserCurrentTaskbarItemListPrioMutationCalls,
} from '#desktop/entities/user/current/graphql/mutations/userCurrentTaskbarItemListPrio.mocks.ts'
import {
  mockUserCurrentTaskbarItemListQuery,
  waitForUserCurrentTaskbarItemListQueryCalls,
} from '#desktop/entities/user/current/graphql/queries/userCurrentTaskbarItemList.mocks.ts'
import { getUserCurrentTaskbarItemListUpdatesSubscriptionHandler } from '#desktop/entities/user/current/graphql/subscriptions/userCurrentTaskbarItemListUpdates.mocks.ts'
import { getUserCurrentTaskbarItemUpdatesSubscriptionHandler } from '#desktop/entities/user/current/graphql/subscriptions/userCurrentTaskbarItemUpdates.mocks.ts'
import { useUserCurrentTaskbarTabsStore } from '#desktop/entities/user/current/stores/taskbarTabs.ts'

import UserTaskbarTabs, { type Props } from '../UserTaskbarTabs.vue'

import '#tests/graphql/builders/mocks.ts'

const waitForVariantConfirmationMock = vi
  .fn()
  .mockImplementation((variant) => variant === 'unsaved')

vi.mock('#shared/composables/useConfirmation.ts', async () => ({
  useConfirmation: () => ({
    waitForVariantConfirmation: waitForVariantConfirmationMock,
  }),
}))

const renderUserTaskbarTabs = async (
  options: {
    props?: Partial<Props>
    routerRoutes?: RouteRecordRaw[]
  } = {},
) => {
  const wrapper = renderComponent(UserTaskbarTabs, {
    router: true,
    store: true,
    dialog: true,
    ...options,
  })

  await waitForUserCurrentTaskbarItemListQueryCalls()
  await waitForNextTick() // initial list render
  await waitForNextTick() // computed async for teleport content

  return wrapper
}

describe('UserTaskbarTabs.vue', () => {
  beforeAll(() => {
    mockApplicationConfig({
      ticket_hook: 'Ticket#',
      ui_task_mananger_max_task_count: 30,
    })
  })

  it.each([{ collapsed: false }, { collapsed: true }])(
    'does not render anything in case taskbar is empty (collapsed: $collapsed)',
    async ({ collapsed }) => {
      mockUserCurrentTaskbarItemListQuery({
        userCurrentTaskbarItemList: [],
      })

      const wrapper = await renderUserTaskbarTabs({
        props: {
          collapsed,
        },
      })

      expect(wrapper.queryByText('Tabs')).not.toBeInTheDocument()

      expect(
        wrapper.queryByRole('button', {
          name: 'List of all user taskbar tabs',
        }),
      ).not.toBeInTheDocument()
    },
  )

  it('renders ticket tab', async () => {
    // Rely on the default ticket tab from the `UserTaskbarItem` factory.
    const wrapper = await renderUserTaskbarTabs({
      routerRoutes: [
        {
          path: '/',
          name: 'Main',
          component: { template: '<div></div>' },
        },
        {
          path: '/tickets/1',
          name: 'Test',
          component: { template: '<div></div>' },
        },
      ],
    })

    expect(wrapper.getByText('Tabs')).toBeInTheDocument()

    const tab = wrapper.getByRole('listitem')

    expect(getByIconName(tab, 'check-circle-no')).toBeInTheDocument()
    expect(tab).toHaveTextContent('Welcome to Zammad!')

    const link = getByRole(tab, 'link')

    expect(link).toHaveAttribute('href', '/desktop/tickets/1')
    expect(link).toHaveAccessibleName('Ticket#53001 - Welcome to Zammad!')
    expect(link).not.toHaveClass('router-link-active router-link-exact-active')

    // Test active background based on the open state.
    const router = getTestRouter()
    await router.push('/tickets/1')

    expect(link).toHaveClass('router-link-active router-link-exact-active')

    expect(getByRole(tab, 'button', { name: 'Close this tab' })).toBeInTheDocument()
  })

  it('renders ticket create tab', async () => {
    mockUserCurrentTaskbarItemListQuery({
      userCurrentTaskbarItemList: [
        {
          __typename: 'UserTaskbarItem',
          id: convertToGraphQLId('Taskbar', 1),
          key: 'TicketCreateScreen-999',
          callback: EnumTaskbarEntity.TicketCreate,
          entityAccess: EnumTaskbarEntityAccess.Granted,
          entity: {
            __typename: 'UserTaskbarItemEntityTicketCreate',
            uid: '999',
            title: 'Test title',
            createArticleTypeKey: 'phone-in',
          },
        },
      ],
    })

    const wrapper = await renderUserTaskbarTabs()

    expect(wrapper.getByText('Tabs')).toBeInTheDocument()

    const tab = wrapper.getByRole('listitem')

    expect(getByIconName(tab, 'pencil')).toBeInTheDocument()
    expect(tab).toHaveTextContent('Received Call: Test title')

    const link = getByRole(tab, 'link')

    expect(link).toHaveAttribute('href', '/desktop/tickets/create/999')
    expect(link).toHaveAccessibleName('Received Call: Test title')

    expect(getByRole(tab, 'button', { name: 'Close this tab' })).toBeInTheDocument()
  })

  it('renders forbidden tab', async () => {
    mockUserCurrentTaskbarItemListQuery({
      userCurrentTaskbarItemList: [
        {
          __typename: 'UserTaskbarItem',
          id: convertToGraphQLId('Taskbar', 999),
          key: 'Ticket-999',
          callback: EnumTaskbarEntity.TicketZoom,
          entityAccess: EnumTaskbarEntityAccess.Forbidden,
          entity: null,
        },
      ],
    })

    const wrapper = await renderUserTaskbarTabs()

    expect(wrapper.getByText('Tabs')).toBeInTheDocument()

    const tab = wrapper.getByRole('listitem')

    expect(getAllByIconName(tab, 'x-lg')[1]).toHaveClass('text-red-500')
    expect(tab).toHaveTextContent('Access denied')

    const link = getByRole(tab, 'link')

    expect(link).toHaveAttribute('href', '/desktop/tickets/999')

    expect(link).toHaveAccessibleName('You have insufficient rights to view this object.')

    expect(getByRole(tab, 'button', { name: 'Close this tab' })).toBeInTheDocument()
  })

  it('renders not found tab', async () => {
    mockUserCurrentTaskbarItemListQuery({
      userCurrentTaskbarItemList: [
        {
          __typename: 'UserTaskbarItem',
          id: convertToGraphQLId('Taskbar', 999),
          key: 'Ticket-999',
          callback: EnumTaskbarEntity.TicketZoom,
          entityAccess: EnumTaskbarEntityAccess.NotFound,
          entity: null,
        },
      ],
    })

    const wrapper = await renderUserTaskbarTabs()

    expect(wrapper.getByText('Tabs')).toBeInTheDocument()

    const tab = wrapper.getByRole('listitem')

    expect(getAllByIconName(tab, 'x-lg')[1]).toHaveClass('text-red-500')
    expect(tab).toHaveTextContent('Not found')

    const link = getByRole(tab, 'link')

    expect(link).toHaveAttribute('href', '/desktop/tickets/999')
    expect(link).toHaveAccessibleName('This object could not be found.')

    expect(getByRole(tab, 'button', { name: 'Close this tab' })).toBeInTheDocument()
  })

  it('renders popover button in collapsed mode', async () => {
    // Rely on the default ticket tab from the `UserTaskbarItem` factory.
    const wrapper = await renderUserTaskbarTabs({
      props: {
        collapsed: true,
      },
    })

    expect(wrapper.queryByText('Tabs')).not.toBeInTheDocument()

    const popoverButton = wrapper.getByRole('button', {
      name: 'List of all user taskbar tabs',
    })

    expect(getByIconName(popoverButton, 'card-list')).toBeInTheDocument()

    await wrapper.events.click(popoverButton)

    const popover = wrapper.getByRole('region', {
      name: 'List of all user taskbar tabs',
    })

    const tab = getByRole(popover, 'listitem')

    expect(getByIconName(tab, 'check-circle-no')).toBeInTheDocument()
    expect(tab).toHaveTextContent('Welcome to Zammad!')

    const link = getByRole(tab, 'link')

    expect(link).toHaveAttribute('href', '/desktop/tickets/1')
    expect(link).toHaveAccessibleName('Ticket#53001 - Welcome to Zammad!')

    await wrapper.events.click(link)

    expect(link).toHaveClass('router-link-active router-link-exact-active')

    expect(getByRole(tab, 'button', { name: 'Close this tab' })).toBeInTheDocument()
  })

  it('implements tab updates subscription', async () => {
    mockUserCurrentTaskbarItemListQuery({
      userCurrentTaskbarItemList: [],
    })

    const wrapper = await renderUserTaskbarTabs()

    expect(wrapper.queryByText('Tabs')).not.toBeInTheDocument()

    // Add item.
    await getUserCurrentTaskbarItemUpdatesSubscriptionHandler().trigger({
      userCurrentTaskbarItemUpdates: {
        addItem: {
          __typename: 'UserTaskbarItem',
          id: convertToGraphQLId('Taskbar', 42),
          key: 'Ticket-42',
          callback: EnumTaskbarEntity.TicketZoom,
          entityAccess: EnumTaskbarEntityAccess.Granted,
          entity: {
            __typename: 'Ticket',
            id: convertToGraphQLId('Ticket', 42),
            internalId: 42,
            number: '53042',
            title: 'Test ticket title',
            stateColorCode: EnumTicketStateColorCode.Pending,
            state: {
              __typename: 'TicketState',
              name: 'pending reminder',
            },
          },
        },
        updateItem: null,
        removeItem: null,
      },
    })

    expect(wrapper.queryByText('Tabs')).toBeInTheDocument()
    expect(wrapper.getByText('Test ticket title')).toBeInTheDocument()

    // Update item.
    await getUserCurrentTaskbarItemUpdatesSubscriptionHandler().trigger({
      userCurrentTaskbarItemUpdates: {
        addItem: null,
        updateItem: {
          __typename: 'UserTaskbarItem',
          id: convertToGraphQLId('Taskbar', 42),
          key: 'Ticket-42',
          callback: EnumTaskbarEntity.TicketZoom,
          entityAccess: EnumTaskbarEntityAccess.Granted,
          entity: {
            __typename: 'Ticket',
            id: convertToGraphQLId('Ticket', 42),
            internalId: 42,
            number: '53042',
            title: 'New ticket title',
            stateColorCode: EnumTicketStateColorCode.Open,
            state: {
              __typename: 'TicketState',
              name: 'open',
            },
          },
        },
        removeItem: null,
      },
    })

    expect(wrapper.queryByText('Test ticket title')).not.toBeInTheDocument()
    expect(wrapper.getByText('New ticket title')).toBeInTheDocument()

    // Remove item.
    await getUserCurrentTaskbarItemUpdatesSubscriptionHandler().trigger({
      userCurrentTaskbarItemUpdates: {
        addItem: null,
        updateItem: null,
        removeItem: convertToGraphQLId('Taskbar', 42),
      },
    })

    expect(wrapper.queryByText('New ticket title')).not.toBeInTheDocument()
  })

  it('supports updating the tabs after they got reordered', async () => {
    mockUserCurrentTaskbarItemListQuery({
      userCurrentTaskbarItemList: [
        {
          __typename: 'UserTaskbarItem',
          id: convertToGraphQLId('Taskbar', 1),
          key: 'TicketCreateScreen-999',
          callback: EnumTaskbarEntity.TicketCreate,
          entityAccess: EnumTaskbarEntityAccess.Granted,
          entity: {
            __typename: 'UserTaskbarItemEntityTicketCreate',
            uid: '999',
            title: 'First ticket',
            createArticleTypeKey: 'phone-in',
          },
          prio: 1,
          formId: 'foo',
          changed: false,
          dirty: false,
          notify: false,
          updatedAt: '2024-07-24T15:42:28.212Z',
        },
        {
          __typename: 'UserTaskbarItem',
          id: convertToGraphQLId('Taskbar', 2),
          key: 'Ticket-42',
          callback: EnumTaskbarEntity.TicketZoom,
          entityAccess: EnumTaskbarEntityAccess.Granted,
          entity: {
            __typename: 'Ticket',
            id: convertToGraphQLId('Ticket', 42),
            internalId: 42,
            number: '53042',
            title: 'Second ticket',
            stateColorCode: EnumTicketStateColorCode.Pending,
            state: {
              __typename: 'TicketState',
              name: 'pending reminder',
            },
          },
          prio: 2,
          formId: 'bar',
          changed: false,
          dirty: false,
          notify: false,
          updatedAt: '2024-07-24T15:42:28.212Z',
        },
      ],
    })

    const wrapper = await renderUserTaskbarTabs()

    expect(wrapper.getByText('Tabs')).toBeInTheDocument()

    let tabs = wrapper.getAllByRole('listitem')

    expect(tabs).toHaveLength(2)
    expect(tabs[0]).toHaveTextContent('First ticket')
    expect(tabs[1]).toHaveTextContent('Second ticket')

    // Reorder tabs.
    await getUserCurrentTaskbarItemListUpdatesSubscriptionHandler().trigger({
      userCurrentTaskbarItemListUpdates: {
        __typename: 'UserCurrentTaskbarItemListUpdatesPayload',
        taskbarItemList: [
          {
            __typename: 'UserTaskbarItem',
            id: convertToGraphQLId('Taskbar', 2),
            prio: 1,
          },
          {
            __typename: 'UserTaskbarItem',
            id: convertToGraphQLId('Taskbar', 1),
            prio: 2,
          },
        ],
      },
    })

    tabs = wrapper.getAllByRole('listitem')

    expect(tabs).toHaveLength(2)
    expect(tabs[0]).toHaveTextContent('Second ticket')
    expect(tabs[1]).toHaveTextContent('First ticket')
  })

  it('supports reordering tabs via keyboard drag-and-drop', async () => {
    mockUserCurrentTaskbarItemListPrioMutation({
      userCurrentTaskbarItemListPrio: {
        __typename: 'UserCurrentTaskbarItemListPrioPayload',
        success: true,
        errors: [],
      },
    })

    mockUserCurrentTaskbarItemListQuery({
      userCurrentTaskbarItemList: [
        {
          __typename: 'UserTaskbarItem',
          id: convertToGraphQLId('Taskbar', 1),
          key: 'Ticket-41',
          callback: EnumTaskbarEntity.TicketZoom,
          entityAccess: EnumTaskbarEntityAccess.Granted,
          entity: {
            __typename: 'Ticket',
            id: convertToGraphQLId('Ticket', 41),
            internalId: 41,
            number: '53041',
            title: 'First ticket',
            stateColorCode: EnumTicketStateColorCode.Open,
            state: {
              __typename: 'TicketState',
              name: 'open',
            },
          },
          prio: 1,
          formId: 'foo',
          changed: false,
          dirty: false,
          notify: false,
          updatedAt: '2024-07-24T15:42:28.212Z',
        },
        {
          __typename: 'UserTaskbarItem',
          id: convertToGraphQLId('Taskbar', 2),
          key: 'Ticket-42',
          callback: EnumTaskbarEntity.TicketZoom,
          entityAccess: EnumTaskbarEntityAccess.Granted,
          entity: {
            __typename: 'Ticket',
            id: convertToGraphQLId('Ticket', 42),
            internalId: 42,
            number: '53042',
            title: 'Second ticket',
            stateColorCode: EnumTicketStateColorCode.Pending,
            state: {
              __typename: 'TicketState',
              name: 'pending reminder',
            },
          },
          prio: 2,
          formId: 'bar',
          changed: false,
          dirty: false,
          notify: false,
          updatedAt: '2024-07-24T15:42:28.212Z',
        },
      ],
    })

    const wrapper = await renderUserTaskbarTabs()

    let tabs = wrapper.getAllByRole('listitem')
    expect(tabs).toHaveLength(2)
    expect(tabs[0]).toHaveTextContent('First ticket')
    expect(tabs[1]).toHaveTextContent('Second ticket')

    // Focus on the sortable list and select the first item
    const list = wrapper.getByRole('list', { name: 'User taskbar tabs' })
    list.focus()

    const messageNodeId = 'announcer-message'

    expect(list.getAttribute('aria-describedby')).toBe(messageNodeId)

    expect(wrapper.getByTestId(messageNodeId)).toHaveTextContent(
      'Sortable list focused. Use up and down arrows to navigate items. Press Space to select and item and again on another item to swap them.',
    )

    await wrapper.events.keyboard('{Space}') // select first

    expect(wrapper.getByTestId(messageNodeId)).toHaveTextContent(
      'Ticket-41 selected. Use arrow keys to choose drop position, then press Space.',
    )

    // Move to second item and confirm swap
    await wrapper.events.keyboard('{ArrowDown}')

    expect(wrapper.getByTestId(messageNodeId)).toHaveTextContent('Focus on Ticket-42')

    await wrapper.events.keyboard('{Space}') // swap first <-> second

    expect(wrapper.getByTestId(messageNodeId)).toHaveTextContent(
      'Swapped Ticket-41 with Ticket-42. Ticket-41 moved to position 2.',
    )

    const calls = await waitForUserCurrentTaskbarItemListPrioMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      list: [
        { id: convertToGraphQLId('Taskbar', 2), prio: 1 },
        { id: convertToGraphQLId('Taskbar', 1), prio: 2 },
      ],
    })

    tabs = wrapper.getAllByRole('listitem')

    await waitFor(() => expect(tabs[0]).toHaveTextContent('Second ticket'))

    expect(tabs[1]).toHaveTextContent('First ticket')
  })

  it('supports closing tabs', async () => {
    // Rely on the default ticket tab from the `UserTaskbarItem` factory.
    const wrapper = await renderUserTaskbarTabs()

    expect(wrapper.getByText('Tabs')).toBeInTheDocument()

    const tab = wrapper.getByRole('listitem')

    await wrapper.events.click(getByRole(tab, 'button', { name: 'Close this tab' }))

    const calls = await waitForUserCurrentTaskbarItemDeleteMutationCalls()

    expect(waitForVariantConfirmationMock).toHaveBeenCalled()

    expect(calls.at(-1)?.variables).toEqual({
      id: convertToGraphQLId('Taskbar', 1),
    })

    expect(tab).not.toBeInTheDocument()
  })

  it('supports redirecting to previous route when the current tab is closed', async () => {
    mockUserCurrentTaskbarItemListQuery({
      userCurrentTaskbarItemList: [
        {
          __typename: 'UserTaskbarItem',
          id: convertToGraphQLId('Taskbar', 1),
          key: 'TicketCreateScreen-999',
          callback: EnumTaskbarEntity.TicketCreate,
          entityAccess: EnumTaskbarEntityAccess.Granted,
          entity: {
            __typename: 'UserTaskbarItemEntityTicketCreate',
            uid: '999',
            title: 'First ticket',
            createArticleTypeKey: 'phone-in',
          },
          prio: 1,
          formId: 'foo',
          changed: false,
          dirty: false,
          notify: false,
          updatedAt: '2024-07-24T15:42:28.212Z',
        },
        {
          __typename: 'UserTaskbarItem',
          id: convertToGraphQLId('Taskbar', 2),
          key: 'Ticket-42',
          callback: EnumTaskbarEntity.TicketZoom,
          entityAccess: EnumTaskbarEntityAccess.Granted,
          entity: {
            __typename: 'Ticket',
            id: convertToGraphQLId('Ticket', 42),
            internalId: 42,
            number: '53042',
            title: 'Second ticket',
            stateColorCode: EnumTicketStateColorCode.Pending,
            state: {
              __typename: 'TicketState',
              name: 'pending reminder',
            },
          },
          prio: 2,
          formId: 'bar',
          changed: false,
          dirty: false,
          notify: false,
          updatedAt: '2024-07-24T15:42:28.212Z',
        },
      ],
    })

    const wrapper = await renderUserTaskbarTabs()

    // Simulate currently active tab by changing the store state directly.
    //   Normally, this would be set by the route navigation guard (`activeTaskbarTab`).
    const { activeTaskbarTabEntityKey } = storeToRefs(useUserCurrentTaskbarTabsStore())

    activeTaskbarTabEntityKey.value = 'TicketCreateScreen-999'

    // Simulate the history stack by visiting different routes before the current one.
    const router = getTestRouter()
    await router.push('/tickets/42')
    await router.push('/tickets/create/999')

    const tabs = wrapper.getAllByRole('listitem')

    expect(tabs).toHaveLength(2)

    await wrapper.events.click(getByRole(tabs[0], 'button', { name: 'Close this tab' }))

    await waitForUserCurrentTaskbarItemDeleteMutationCalls()

    expect(tabs[0]).not.toBeInTheDocument()

    await getUserCurrentTaskbarItemUpdatesSubscriptionHandler().trigger({
      userCurrentTaskbarItemUpdates: {
        addItem: null,
        updateItem: null,
        removeItem: convertToGraphQLId('Taskbar', 1),
      },
    })

    expect(wrapper, 'correctly redirects to the previous route').toHaveCurrentUrl('/tickets/42')
  })
})
