// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { convertToGraphQLId } from '@shared/graphql/utils'
import { getTestRouter } from '@tests/support/components/renderComponent'
import { visitView } from '@tests/support/components/visitView'
import type { MockGraphQLInstance } from '@tests/support/mock-graphql-api'
import { setupView } from '@tests/support/mock-user'
import {
  nullableMock,
  waitUntil,
  waitUntilApisResolved,
} from '@tests/support/utils'
import { mockSearchOverview } from '../graphql/mocks/mockSearchOverview'

describe('visiting search page', () => {
  let mockSearchApi: MockGraphQLInstance

  beforeEach(() => {
    mockSearchApi = mockSearchOverview([])
    setupView('agent')
  })

  it('doesnt search if no type is selected', async () => {
    const view = await visitView('/search')

    const searchInput = view.getByPlaceholderText('Search…')
    await view.events.type(searchInput, 'search')

    expect(mockSearchApi.spies.resolve).not.toHaveBeenCalled()
  })

  it('allows searching', async () => {
    const view = await visitView('/search')

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

    await waitUntil(() => mockSearchApi.calls.resolve)

    expect(mockSearchApi.spies.resolve).toHaveBeenCalledWith({
      onlyIn: 'User',
      isAgent: true,
      search: 'search',
    })

    expect(view.container).toHaveTextContent('No entries')

    await view.events.click(view.getByText('Organizations'))

    expect(mockSearchApi.spies.resolve).toHaveBeenCalledWith({
      onlyIn: 'Organization',
      isAgent: true,
      search: 'search',
    })

    expect(view.getByRole('tab', { name: 'Organizations' })).toHaveFocus()
  })

  it('renders correctly if queries are passed down', async () => {
    const view = await visitView('/search/invalid?search=search')

    expect(view.getByPlaceholderText('Search…')).toHaveDisplayValue('search')
    expect(view.getByTestId('selectTypesSection')).toBeInTheDocument()
  })

  it('opens with type, if there is only single type', async () => {
    // customer can only search for tickets
    setupView('customer')
    await visitView('/search')
    expect(getTestRouter().currentRoute.value.fullPath).toBe('/search/ticket')
  })
})

describe('avatars', () => {
  it('renders user as inactive', async () => {
    setupView('agent')
    const mockSearch = mockSearchOverview([
      nullableMock({
        __typename: 'User',
        id: convertToGraphQLId('User', 100),
        internalId: 100,
        updatedAt: new Date().toISOString(),
        active: false,
        vip: true,
        firstname: 'Max',
        lastname: 'Mustermann',
      }),
      nullableMock({
        __typename: 'User',
        id: convertToGraphQLId('User', 200),
        internalId: 200,
        updatedAt: new Date().toISOString(),
        outOfOffice: true,
        active: true,
        image: 'jon.png',
        firstname: 'Jon',
        lastname: 'Doe',
      }),
    ])

    const view = await visitView('/search/user?search=max')

    await waitUntilApisResolved(mockSearch)

    expect(
      view.getByLabelText('Avatar (Max Mustermann) (VIP)'),
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
