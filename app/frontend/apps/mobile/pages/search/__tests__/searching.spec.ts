// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  getGraphQLMockCalls,
  mockGraphQLResult,
} from '#tests/graphql/builders/mocks.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { setupView } from '#tests/support/mock-user.ts'

import type { SearchQuery } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { SearchDocument } from '../graphql/queries/searchOverview.api.ts'

describe('visiting search page', () => {
  beforeEach(() => {
    setupView('agent')
  })

  it('doesnt search if no type is selected', async () => {
    const view = await visitView('/search', { mockApollo: false })

    const searchInput = view.getByPlaceholderText('Search…')
    await view.events.type(searchInput, 'search')

    expect(getGraphQLMockCalls(SearchDocument)).toHaveLength(0)
  })

  it('allows searching', async () => {
    const view = await visitView('/search', { mockApollo: false })

    const mocker = mockGraphQLResult<SearchQuery>(SearchDocument, {
      search: [],
    })

    const searchInput = view.getByPlaceholderText('Search…')

    expect(searchInput).toHaveFocus()
    // don't show until query is entered
    expect(view.queryByTestId('selectTypesSection')).not.toBeInTheDocument()

    await view.events.type(searchInput, 'search')

    // show types when query is entered
    expect(view.getByTestId('selectTypesSection')).toBeInTheDocument()

    await view.events.click(view.getByText('Users with "search"'))

    // focus shifted to tab with the same type
    expect(view.getByRole('tab', { name: 'Users' })).toHaveFocus()

    const mockCalls = await mocker.waitForCalls()

    expect(mockCalls).toHaveLength(1)
    expect(mockCalls[0].variables).toEqual({
      onlyIn: 'User',
      search: 'search',
      limit: 30,
    })

    expect(view.container).toHaveTextContent('No entries')

    await view.events.click(view.getByText('Organizations'))

    expect(mockCalls).toHaveLength(2)
    expect(mockCalls[1].variables).toEqual({
      onlyIn: 'Organization',
      search: 'search',
      limit: 30,
    })

    expect(view.getByRole('tab', { name: 'Organizations' })).toHaveFocus()
  })

  it('renders correctly if queries are passed down', async () => {
    const view = await visitView('/search/invalid?search=search', {
      mockApollo: false,
    })

    expect(view.getByPlaceholderText('Search…')).toHaveDisplayValue('search')
    expect(view.getByTestId('selectTypesSection')).toBeInTheDocument()
  })

  it('opens with type, if there is only single type', async () => {
    // customer can only search for tickets
    setupView('customer')
    await visitView('/search', { mockApollo: false })
    expect(getTestRouter().currentRoute.value.fullPath).toBe('/search/ticket')
  })
})

describe('avatars', () => {
  it('renders user as inactive', async () => {
    setupView('agent')
    mockGraphQLResult<SearchQuery>(SearchDocument, {
      search: [
        {
          __typename: 'User',
          id: convertToGraphQLId('User', 100),
          internalId: 100,
          updatedAt: new Date().toISOString(),
          active: false,
          vip: true,
          firstname: 'Max',
          lastname: 'Mustermann',
        },
        {
          __typename: 'User',
          id: convertToGraphQLId('User', 200),
          internalId: 200,
          updatedAt: new Date().toISOString(),
          outOfOffice: true,
          active: true,
          vip: false,
          image: 'jon.png',
          firstname: 'Jon',
          lastname: 'Doe',
        },
      ],
    })

    const view = await visitView('/search/user?search=max', {
      mockApollo: false,
    })

    expect(
      await view.findByLabelText('Avatar (Max Mustermann) (VIP)'),
    ).toBeAvatarElement({
      active: false,
      vip: true,
      type: 'user',
    })

    expect(view.getByLabelText('Avatar (Jon Doe)')).toBeAvatarElement({
      active: true,
      vip: false,
      outOfOffice: true,
      image: 'jon.png',
      type: 'user',
    })
  })
})

test('correctly redirects from hash-based routes', async () => {
  setupView('agent')
  mockGraphQLResult<SearchQuery>(SearchDocument, {
    search: [],
  })
  await visitView('/#search/string', { mockApollo: false })
  const router = getTestRouter()
  const route = router.currentRoute.value
  expect(route.name).toBe('SearchOverview')
  expect(route.params).toEqual({ type: 'ticket' })
  expect(route.query).toEqual({ search: 'string' })
})
