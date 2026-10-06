// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import renderComponent, { initializePiniaStore } from '#tests/support/components/renderComponent.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { nullableMock, waitForNextTick } from '#tests/support/utils.ts'

import { useRecentSearches } from '#shared/composables/useRecentSearches.ts'
import {
  EnumTicketStateColorCode,
  type Organization,
  type Ticket,
  type User,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockUserCurrentRecentCloseResetMutation } from '#desktop/entities/user/current/graphql/mutations/userCurrentRecentCloseReset.mocks.ts'
import { mockUserCurrentRecentCloseListQuery } from '#desktop/entities/user/current/graphql/queries/userCurrentRecentCloseList.mocks.ts'
import { getUserCurrentRecentCloseUpdatesSubscriptionHandler } from '#desktop/entities/user/current/graphql/subscriptions/userCurrentRecentCloseUpdates.mocks.ts'

import { mockQuickSearchQuery } from '../../graphql/queries/quickSearch.mocks.ts'
import QuickSearch from '../QuickSearch.vue'

// The recent-search prompts go through the shared composable; the dialog itself is not mounted
//   here, so the examples assert what it is asked with.
const mockWaitForConfirmation = vi.hoisted(() => vi.fn())

vi.mock('#shared/composables/useConfirmation.ts', () => ({
  useConfirmation: () => ({ waitForConfirmation: mockWaitForConfirmation }),
}))

beforeEach(() => {
  mockWaitForConfirmation.mockReset()
  mockWaitForConfirmation.mockResolvedValue(true)
})

const renderQuickSearch = async (search: string = '') => {
  const wrapper = renderComponent(QuickSearch, {
    props: {
      collapsed: false,
      search,
    },
    router: true,
    store: true,
    dialog: true,
  })

  await waitForNextTick()

  return wrapper
}

describe('QuickSearch', () => {
  initializePiniaStore()

  const { addSearch, removeSearch, clearSearches } = useRecentSearches()

  beforeEach(() => {
    clearSearches()
  })

  describe('default state', () => {
    it('shows empty state message when no searches or recently closed items exist', async () => {
      mockUserCurrentRecentCloseListQuery({ userCurrentRecentCloseList: [] })

      const wrapper = await renderQuickSearch()

      expect(
        wrapper.getByText('Start typing e.g. the name of a ticket, an organization or a user.'),
      ).toBeInTheDocument()

      expect(wrapper.queryByRole('button', { name: 'Clear all' })).not.toBeInTheDocument()
    })
  })

  describe('recent searches', () => {
    beforeEach(() => {
      mockUserCurrentRecentCloseListQuery({ userCurrentRecentCloseList: [] })
    })

    it('displays recent searches when added', async () => {
      const wrapper = await renderQuickSearch()

      addSearch('Foobar')
      addSearch('Dummy')
      await waitForNextTick()

      expect(
        wrapper.getByRole('heading', { level: 3, name: 'Recent searches' }),
      ).toBeInTheDocument()

      expect(wrapper.getByText('Foobar')).toBeInTheDocument()
      expect(wrapper.getByText('Dummy')).toBeInTheDocument()

      expect(wrapper.getByRole('link', { name: 'Clear recent searches' })).toBeInTheDocument()
    })

    it('allows clearing all recent searches', async () => {
      const wrapper = await renderQuickSearch()

      addSearch('Foobar')
      addSearch('Dummy')
      await waitForNextTick()

      expect(wrapper.getByRole('link', { name: 'Clear recent searches' })).toBeInTheDocument()

      clearSearches()
      await waitForNextTick()

      expect(
        wrapper.getByText('Start typing e.g. the name of a ticket, an organization or a user.'),
      ).toBeInTheDocument()

      expect(wrapper.queryByRole('link', { name: 'Clear recent searches' })).not.toBeInTheDocument()
    })

    it('allows removing individual recent searches', async () => {
      const wrapper = await renderQuickSearch()

      addSearch('Foobar')
      addSearch('Dummy')
      await waitForNextTick()

      let removeIcons = wrapper.getAllByIconName('x-lg')
      expect(removeIcons.length).toBe(2)

      removeSearch('Foobar')
      await waitForNextTick()

      removeIcons = wrapper.getAllByIconName('x-lg')
      expect(removeIcons.length).toBe(1)
    })

    // Removing asks first, so the trigger is not red; the confirm button inside the dialog is.
    it('asks before removing a recent search, with a danger confirm button', async () => {
      const wrapper = await renderQuickSearch()

      addSearch('Foobar')
      await waitForNextTick()

      const removeButton = wrapper.getByRole('button', { name: 'Delete this recent search' })

      expect(removeButton).toHaveClass('bg-green-200')
      expect(removeButton).not.toHaveClass('bg-red-400')

      await wrapper.events.click(removeButton)

      expect(mockWaitForConfirmation).toHaveBeenCalledWith(
        'Are you sure? This recent search will be lost.',
        expect.objectContaining({ buttonVariant: 'danger' }),
      )
    })

    it('asks before clearing the recent searches, with a danger confirm button', async () => {
      const wrapper = await renderQuickSearch()

      addSearch('Foobar')
      await waitForNextTick()

      await wrapper.events.click(wrapper.getByRole('link', { name: 'Clear recent searches' }))

      expect(mockWaitForConfirmation).toHaveBeenCalledWith(
        'Are you sure? Your recent searches will be lost.',
        expect.objectContaining({ buttonVariant: 'danger' }),
      )
    })
  })

  describe('recently closed items', () => {
    const recentlyClosedItems = [
      {
        __typename: 'Ticket',
        id: convertToGraphQLId('Ticket', 2),
        title: 'Ticket 1',
        number: '1',
        state: nullableMock({
          id: convertToGraphQLId('TicketState', 1),
          name: 'open',
        }),
        stateColorCode: EnumTicketStateColorCode.Open,
      } as Ticket,
      {
        __typename: 'User',
        id: convertToGraphQLId('User', 2),
        internalId: 2,
        fullname: 'User 1',
      } as User,
      {
        __typename: 'Organization',
        id: convertToGraphQLId('Organization', 2),
        internalId: 2,
        name: 'Organization 1',
      } as Organization,
    ]

    it('displays recently closed items', async () => {
      mockPermissions(['ticket.agent'])
      mockUserCurrentRecentCloseListQuery({
        userCurrentRecentCloseList: recentlyClosedItems,
      })

      const wrapper = await renderQuickSearch()

      expect(
        wrapper.getByRole('heading', { level: 3, name: 'Recently closed' }),
      ).toBeInTheDocument()

      expect(wrapper.getByRole('link', { name: 'openTicket 1' })).toBeInTheDocument()

      expect(wrapper.getByRole('link', { name: 'User 1' })).toBeInTheDocument()

      expect(wrapper.getByRole('link', { name: 'Organization 1' })).toBeInTheDocument()
    })

    // The same loss as clearing the recent searches, so this dialog confirms in danger as well.
    it('asks before clearing the recently closed items, with a danger confirm button', async () => {
      mockPermissions(['ticket.agent'])
      mockUserCurrentRecentCloseListQuery({
        userCurrentRecentCloseList: recentlyClosedItems,
      })
      mockWaitForConfirmation.mockResolvedValue(false)

      const wrapper = await renderQuickSearch()

      await wrapper.events.click(wrapper.getByRole('link', { name: 'Clear recently closed' }))

      expect(mockWaitForConfirmation).toHaveBeenCalledWith(
        'Are you sure? Your recently closed items will get lost.',
        expect.objectContaining({ buttonVariant: 'danger' }),
      )
    })

    it('allows clearing all recently closed items', async () => {
      mockUserCurrentRecentCloseListQuery({
        userCurrentRecentCloseList: recentlyClosedItems,
      })

      mockUserCurrentRecentCloseResetMutation({
        userCurrentRecentCloseReset: { success: true },
      })

      const wrapper = await renderQuickSearch()

      expect(wrapper.getByRole('link', { name: 'Clear recently closed' })).toBeInTheDocument()

      mockUserCurrentRecentCloseListQuery({ userCurrentRecentCloseList: [] })

      await getUserCurrentRecentCloseUpdatesSubscriptionHandler().trigger({
        userCurrentRecentCloseUpdates: {
          recentCloseUpdated: true,
        },
      })

      await waitForNextTick()

      expect(
        wrapper.getByText('Start typing e.g. the name of a ticket, an organization or a user.'),
      ).toBeInTheDocument()

      expect(wrapper.queryByRole('link', { name: 'Clear recently closed' })).not.toBeInTheDocument()
    })

    it('display search results when typing', async () => {
      mockQuickSearchQuery({
        quickSearchUsers: {
          totalCount: 0,
          items: [],
        },
        quickSearchOrganizations: {
          totalCount: 0,
          items: [],
        },
        quickSearchTickets: {
          totalCount: 0,
          items: [],
        },
      })

      const wrapper = await renderQuickSearch('test')

      expect(await wrapper.findByText('No results for this query.')).toBeInTheDocument()
    })
  })
})
