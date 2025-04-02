// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { useRecentSearches } from '#shared/composables/useRecentSearches.ts'
import {
  EnumTicketStateColorCode,
  type Organization,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockUserCurrentRecentViewResetMutation } from '#desktop/entities/user/current/graphql/mutations/userCurrentRecentViewReset.mocks.ts'
import { mockUserCurrentRecentViewListQuery } from '#desktop/entities/user/current/graphql/queries/userCurrentRecentViewList.mocks.ts'
import { getUserCurrentRecentViewUpdatesSubscriptionHandler } from '#desktop/entities/user/current/graphql/subscriptions/userCurrentRecentViewUpdates.mocks.ts'

import { mockQuickSearchQuery } from '../../graphql/queries/quickSearch.mocks.ts'
import QuickSearch from '../QuickSearch.vue'

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

mockUserCurrent()

describe('QuickSearch', () => {
  const { addSearch, removeSearch, clearSearches } = useRecentSearches()

  beforeEach(() => {
    clearSearches()
  })

  describe('default state', () => {
    it('shows empty state message when no searches or recently viewed items exist', async () => {
      mockUserCurrentRecentViewListQuery({ userCurrentRecentViewList: [] })

      const wrapper = await renderQuickSearch()

      expect(
        wrapper.getByText(
          'Start typing e.g. the name of a ticket, an organization or a user.',
        ),
      ).toBeInTheDocument()

      expect(
        wrapper.queryByRole('button', { name: 'Clear All' }),
      ).not.toBeInTheDocument()
    })
  })

  describe('recent searches', () => {
    beforeEach(() => {
      mockUserCurrentRecentViewListQuery({ userCurrentRecentViewList: [] })
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

      expect(
        wrapper.getByRole('link', { name: 'Clear recent searches' }),
      ).toBeInTheDocument()
    })

    it('allows clearing all recent searches', async () => {
      const wrapper = await renderQuickSearch()

      addSearch('Foobar')
      addSearch('Dummy')
      await waitForNextTick()

      expect(
        wrapper.getByRole('link', { name: 'Clear recent searches' }),
      ).toBeInTheDocument()

      clearSearches()
      await waitForNextTick()

      expect(
        wrapper.getByText(
          'Start typing e.g. the name of a ticket, an organization or a user.',
        ),
      ).toBeInTheDocument()

      expect(
        wrapper.queryByRole('link', { name: 'Clear recent searches' }),
      ).not.toBeInTheDocument()
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
  })

  describe('recently viewed items', () => {
    const recentlyViewedItems = [
      {
        __typename: 'Ticket',
        id: convertToGraphQLId('Ticket', 1),
        title: 'Ticket 1',
        number: '1',
        stateColorCode: EnumTicketStateColorCode.Open,
      },
      {
        __typename: 'User',
        id: convertToGraphQLId('User', 1),
        internalId: 1,
        fullname: 'User 1',
      },
      {
        __typename: 'Organization',
        id: convertToGraphQLId('Organization', 1),
        internalId: 1,
        name: 'Organization 1',
      },
    ]

    it('displays recently viewed items', async () => {
      mockUserCurrentRecentViewListQuery({
        userCurrentRecentViewList: recentlyViewedItems as Organization[],
      })

      const wrapper = await renderQuickSearch()

      expect(
        wrapper.getByRole('heading', { level: 3, name: 'Recently viewed' }),
      ).toBeInTheDocument()

      expect(
        wrapper.getByRole('link', { name: 'check-circle-no Ticket 1' }),
      ).toBeInTheDocument()
      expect(wrapper.getByRole('link', { name: 'User 1' })).toBeInTheDocument()
      expect(
        wrapper.getByRole('link', { name: 'Organization 1' }),
      ).toBeInTheDocument()
    })

    it('allows clearing all recently viewed items', async () => {
      mockUserCurrentRecentViewListQuery({
        userCurrentRecentViewList: recentlyViewedItems as Organization[],
      })

      mockUserCurrentRecentViewResetMutation({
        userCurrentRecentViewReset: { success: true },
      })

      const wrapper = await renderQuickSearch()

      expect(
        wrapper.getByRole('link', { name: 'Clear recently viewed' }),
      ).toBeInTheDocument()

      mockUserCurrentRecentViewListQuery({ userCurrentRecentViewList: [] })

      await getUserCurrentRecentViewUpdatesSubscriptionHandler().trigger({
        userCurrentRecentViewUpdates: {
          recentViewsUpdated: true,
        },
      })

      await waitForNextTick()

      expect(
        wrapper.getByText(
          'Start typing e.g. the name of a ticket, an organization or a user.',
        ),
      ).toBeInTheDocument()

      expect(
        wrapper.queryByRole('link', { name: 'Clear recently viewed' }),
      ).not.toBeInTheDocument()
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

      expect(
        await wrapper.findByText('No results for this query.'),
      ).toBeInTheDocument()
    })
  })
})
