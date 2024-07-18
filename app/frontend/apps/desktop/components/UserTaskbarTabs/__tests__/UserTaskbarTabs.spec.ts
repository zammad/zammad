// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getByRole, queryByRole } from '@testing-library/vue'
import { type RouteRecordRaw } from 'vue-router'

import {
  getAllByIconName,
  getByIconName,
} from '#tests/support/components/iconQueries.ts'
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
  mockUserCurrentTaskbarItemListQuery,
  waitForUserCurrentTaskbarItemListQueryCalls,
} from '#desktop/entities/user/current/graphql/queries/userCurrentTaskbarItemList.mocks.ts'
import { getUserCurrentTaskbarItemUpdatesSubscriptionHandler } from '#desktop/entities/user/current/graphql/subscriptions/userCurrentTaskbarItemUpdates.mocks.ts'

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
  await waitForNextTick()

  return wrapper
}

describe('UserTaskbarTabs.vue', () => {
  beforeAll(() => {
    mockApplicationConfig({
      ticket_hook: 'Ticket#',
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

    expect(tab).toHaveAccessibleDescription(
      'Drag and drop to reorder your tabs.',
    )

    const link = getByRole(tab, 'link')

    expect(link).toHaveAttribute('href', '/desktop/tickets/1')
    expect(link).toHaveAccessibleName('Ticket#53001 - Welcome to Zammad!')
    expect(link).not.toHaveClass('!bg-yellow-500')

    // Test active background based on the open state.
    const router = getTestRouter()
    await router.push('/tickets/1')

    expect(link).toHaveClass('!bg-yellow-500')

    expect(
      getByRole(tab, 'button', { name: 'Close this tab' }),
    ).toBeInTheDocument()
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

    expect(tab).toHaveAccessibleDescription(
      'Drag and drop to reorder your tabs.',
    )

    const link = getByRole(tab, 'link')

    expect(link).toHaveAttribute('href', '/desktop/tickets/create/999')
    expect(link).toHaveAccessibleName('Received Call: Test title')

    expect(
      getByRole(tab, 'button', { name: 'Close this tab' }),
    ).toBeInTheDocument()
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
        },
      ],
    })

    const wrapper = await renderUserTaskbarTabs()

    expect(wrapper.getByText('Tabs')).toBeInTheDocument()

    const tab = wrapper.getByRole('listitem')

    expect(getAllByIconName(tab, 'x-lg')[0]).toHaveClass('text-red-500')
    expect(tab).toHaveTextContent('Access denied')

    expect(tab).toHaveAccessibleDescription(
      'Drag and drop to reorder your tabs.',
    )

    expect(queryByRole(tab, 'link')).not.toBeInTheDocument()

    expect(
      getByRole(tab, 'button', { name: 'Close this tab' }),
    ).toBeInTheDocument()
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
        },
      ],
    })

    const wrapper = await renderUserTaskbarTabs()

    expect(wrapper.getByText('Tabs')).toBeInTheDocument()

    const tab = wrapper.getByRole('listitem')

    expect(getAllByIconName(tab, 'x-lg')[0]).toHaveClass('text-red-500')
    expect(tab).toHaveTextContent('Not found')

    expect(tab).toHaveAccessibleDescription(
      'Drag and drop to reorder your tabs.',
    )

    expect(queryByRole(tab, 'link')).not.toBeInTheDocument()

    expect(
      getByRole(tab, 'button', { name: 'Close this tab' }),
    ).toBeInTheDocument()
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

    expect(tab).not.toHaveAccessibleDescription(
      'Drag and drop to reorder your tabs.',
    )

    const link = getByRole(tab, 'link')

    expect(link).toHaveAttribute('href', '/desktop/tickets/1')
    expect(link).toHaveAccessibleName('Ticket#53001 - Welcome to Zammad!')
    expect(link).toHaveClass('!bg-yellow-500')

    expect(
      getByRole(tab, 'button', { name: 'Close this tab' }),
    ).toBeInTheDocument()
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

  it('supports closing tabs', async () => {
    // Rely on the default ticket tab from the `UserTaskbarItem` factory.
    const wrapper = await renderUserTaskbarTabs()

    expect(wrapper.getByText('Tabs')).toBeInTheDocument()

    const tab = wrapper.getByRole('listitem')

    await wrapper.events.click(
      getByRole(tab, 'button', { name: 'Close this tab' }),
    )

    const calls = await waitForUserCurrentTaskbarItemDeleteMutationCalls()

    expect(waitForVariantConfirmationMock).toHaveBeenCalled()

    expect(calls.at(-1)?.variables).toEqual({
      id: convertToGraphQLId('Taskbar', 1),
    })

    // TODO: Check for correct redirect when implemented.
    await vi.waitFor(() => {
      expect(
        wrapper,
        'correctly redirects to dashboard screen',
      ).toHaveCurrentUrl('/dashboard')
    })
  })
})
