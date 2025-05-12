// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { waitFor } from '@testing-library/vue'

import renderComponent, {
  getTestRouter,
} from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { EnumTicketStateColorCode } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockQuickSearchQuery,
  waitForQuickSearchQueryCalls,
} from '../../../graphql/queries/quickSearch.mocks.ts'
import QuickSearchResultList from '../QuickSearchResultList.vue'

const renderQuickSearchResultList = async (search: string) => {
  const wrapper = renderComponent(QuickSearchResultList, {
    props: {
      search,
      debounceTime: 400,
    },
    router: true,
  })

  await waitForNextTick()

  return wrapper
}

describe('QuickSearchResultList', async () => {
  it('renders by default the sections with an empty state', async () => {
    mockQuickSearchQuery({
      quickSearchOrganizations: {
        totalCount: 0,
        items: [],
      },
      quickSearchUsers: {
        totalCount: 0,
        items: [],
      },
      quickSearchTickets: {
        totalCount: 0,
        items: [],
      },
    })

    const wrapper = await renderQuickSearchResultList('')

    expect(wrapper.queryByText('Found organizations')).not.toBeInTheDocument()
    expect(wrapper.queryByText('Found users')).not.toBeInTheDocument()
    expect(wrapper.queryByText('Found tickets')).not.toBeInTheDocument()

    expect(
      await wrapper.findByText('No results for this query.'),
    ).toBeInTheDocument()
  })

  it('renders the sections with the results', async () => {
    mockPermissions(['ticket.agent', 'admin.user'])
    mockApplicationConfig({ kb_active: true })

    mockQuickSearchQuery({
      quickSearchOrganizations: {
        totalCount: 1,
        items: [
          {
            __typename: 'Organization',
            id: convertToGraphQLId('Organization', 1),
            internalId: 1,
            name: 'Organization 1',
          },
        ],
      },
      quickSearchUsers: {
        totalCount: 1,
        items: [
          {
            __typename: 'User',
            id: convertToGraphQLId('User', 1),
            internalId: 1,
            fullname: 'User 1',
          },
        ],
      },
      quickSearchTickets: {
        totalCount: 100,
        items: [
          {
            __typename: 'Ticket',
            id: convertToGraphQLId('Ticket', 1),
            internalId: 1,
            title: 'Ticket 1',
            number: '1',
            state: {
              __typename: 'TicketState',
              id: convertToGraphQLId('TicketState', 1),
              name: 'open',
            },
            stateColorCode: EnumTicketStateColorCode.Open,
          },
        ],
      },
    })

    const wrapper = await renderQuickSearchResultList('1')

    await waitForQuickSearchQueryCalls()

    expect(wrapper.getByRole('link', { name: '99 more' })).toBeInTheDocument()

    expect(wrapper.getByText('Found organizations')).toBeInTheDocument()
    expect(wrapper.getByText('Found users')).toBeInTheDocument()
    expect(wrapper.getByText('Found tickets')).toBeInTheDocument()

    expect(wrapper.getByText('Found organizations')).toBeInTheDocument()
    expect(wrapper.getByText('Found users')).toBeInTheDocument()
    expect(wrapper.getByText('Found tickets')).toBeInTheDocument()

    expect(
      wrapper.queryByText(
        'Start typing i.e. the name of a ticket, an organization or a user.',
      ),
    ).not.toBeInTheDocument()

    await wrapper.events.click(wrapper.getByRole('link', { name: '99 more' }))

    const router = getTestRouter()

    await waitFor(() => expect(router.currentRoute.value.name).toBe('search'))

    expect(router.currentRoute.value.params).toEqual({ searchTerm: '1' })
    expect(router.currentRoute.value.query).toEqual({ entity: 'Ticket' })
  })

  it('renders inactive users', async () => {
    mockPermissions(['ticket.agent', 'admin.user'])
    mockApplicationConfig({ kb_active: true })

    mockQuickSearchQuery({
      quickSearchUsers: {
        totalCount: 1,
        items: [
          {
            __typename: 'User',
            active: false,
            id: convertToGraphQLId('User', 2),
            internalId: 2,
            fullname: 'User 1',
          },
        ],
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

    const wrapper = await renderQuickSearchResultList('User 1')

    await waitForQuickSearchQueryCalls()

    await wrapper.findByIconName('user-inactive')

    const userLink = wrapper.getByRole('link', { name: 'User 1' })

    expect(wrapper.getByText('User 1')).toHaveClass('text-neutral-500!')

    expect(userLink).toHaveAttribute('aria-description', 'User is inactive.')
  })

  it('renders inactive organization', async () => {
    mockPermissions(['ticket.agent', 'admin.user'])

    mockQuickSearchQuery({
      quickSearchOrganizations: {
        totalCount: 1,
        items: [
          {
            __typename: 'Organization',
            active: false,
            id: convertToGraphQLId('Organization', 1),
            internalId: 1,
            name: 'Organization 1',
          },
        ],
      },
      quickSearchTickets: {
        totalCount: 0,
        items: [],
      },
      quickSearchUsers: {
        totalCount: 0,
        items: [],
      },
    })

    const wrapper = await renderQuickSearchResultList('Organization')

    await waitForQuickSearchQueryCalls()

    await wrapper.findByIconName('buildings-slash')

    const userLink = wrapper.getByRole('link', { name: 'Organization 1' })

    expect(wrapper.getByText('Organization 1')).toHaveClass('text-neutral-500!')
    expect(userLink).toHaveAttribute(
      'aria-description',
      'Organization is inactive.',
    )
  })

  it('renders detailed search button if search term is provided', async () => {
    mockQuickSearchQuery({
      quickSearchOrganizations: {
        totalCount: 0,
        items: [],
      },
      quickSearchUsers: {
        totalCount: 1,
        items: [
          {
            __typename: 'User',
            active: false,
            id: convertToGraphQLId('User', 1),
            internalId: 1,
            fullname: 'User',
          },
        ],
      },
      quickSearchTickets: {
        totalCount: 0,
        items: [],
      },
    })

    const wrapper = await renderQuickSearchResultList('User')

    await waitForQuickSearchQueryCalls()

    const detailedSearchButton = await wrapper.findByRole('link', {
      name: 'detailed search',
    })

    await wrapper.events.click(detailedSearchButton)

    const router = getTestRouter()

    await waitFor(() => expect(router.currentRoute.value.name).toBe('search'))

    expect(router.currentRoute.value.params).toEqual({ searchTerm: 'User' })
  })

  it('hides customer entity from user if application not set', () => {
    mockPermissions(['ticket.agent', 'admin.user'])
    mockApplicationConfig({ kb_active: false })

    mockQuickSearchQuery({
      quickSearchOrganizations: {
        totalCount: 0,
        items: [],
      },
      quickSearchUsers: {
        totalCount: 1,
        items: [
          {
            __typename: 'User',
            active: false,
            id: convertToGraphQLId('User', 1),
            internalId: 1,
            fullname: 'User',
          },
        ],
      },
      quickSearchTickets: {
        totalCount: 0,
        items: [],
      },
    })

    const wrapper = renderComponent(QuickSearchResultList, {
      props: {
        search: '',
        debounceTime: 400,
      },
    })

    expect(wrapper.queryByText('Found users')).not.toBeInTheDocument()
  })

  it('hides organization and users from customer', () => {
    mockPermissions(['ticket.customer'])
    mockApplicationConfig({ kb_active: true })

    // backend should not return any data in this case, but we are testing the frontend code here
    mockQuickSearchQuery({
      quickSearchOrganizations: {
        totalCount: 1,
        items: [
          {
            __typename: 'Organization',
            id: convertToGraphQLId('Organization', 1),
            internalId: 1,
            name: 'Organization 1',
          },
        ],
      },
      quickSearchUsers: {
        totalCount: 1,
        items: [
          {
            __typename: 'User',
            active: false,
            id: convertToGraphQLId('User', 1),
            internalId: 1,
            fullname: 'User',
          },
        ],
      },
      quickSearchTickets: {
        totalCount: 0,
        items: [],
      },
    })

    const wrapper = renderComponent(QuickSearchResultList, {
      props: {
        search: '',
        debounceTime: 400,
      },
    })

    expect(wrapper.queryByText('Found users')).not.toBeInTheDocument()
    expect(wrapper.queryByText('Found organizations')).not.toBeInTheDocument()
  })
})
