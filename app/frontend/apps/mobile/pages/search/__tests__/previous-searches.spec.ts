// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getByText, getAllByRole } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { clearMockClient } from '#tests/support/mock-apollo-client.ts'
import type { MockGraphQLInstance } from '#tests/support/mock-graphql-api.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { nullableMock, waitUntil } from '#tests/support/utils.ts'

import { mockSearchOverview } from '../graphql/mocks/mockSearchOverview.ts'

describe('testing previous searches block', () => {
  let mockSearchApi: MockGraphQLInstance

  beforeEach(() => {
    mockPermissions(['ticket.agent'])
    mockSearchApi = mockSearchOverview([])
  })

  it('previous searches', async () => {
    localStorage.clear()
    const view = await visitView('/search/user')

    const getByTextInLastSearch = (text: string) => {
      return getByText(view.getByTestId('lastSearches'), text)
    }

    const typeInSearch = async (text: string) => {
      await view.events.debounced(() =>
        view.events.type(view.getByPlaceholderText('Search…'), text),
      )
      await waitUntil(() => mockSearchApi.calls.resolve)
    }
    const clearSearch = () => {
      return view.events.debounced(() =>
        view.events.clear(view.getByPlaceholderText('Search…')),
      )
    }

    expect(getByTextInLastSearch('No previous searches')).toBeInTheDocument()

    await typeInSearch('search')

    expect(getByTextInLastSearch('search')).toBeInTheDocument()

    await typeInSearch('123')

    expect(getByTextInLastSearch('search123')).toBeInTheDocument()

    await clearSearch()
    await typeInSearch('search')

    let items = getAllByRole(view.getByTestId('lastSearches'), 'listitem')
    expect(items).toHaveLength(2)
    expect(items[0]).toHaveTextContent(/^search$/)
    expect(items[1]).toHaveTextContent(/^search123$/)

    await clearSearch()
    await typeInSearch('test 1')

    await clearSearch()
    await typeInSearch('test 2')

    await clearSearch()
    await typeInSearch('test 3')

    items = getAllByRole(view.getByTestId('lastSearches'), 'listitem')
    expect(items).toHaveLength(5)
    expect(items[0]).toHaveTextContent(/^test 3$/)
    expect(items[1]).toHaveTextContent(/^test 2$/)
    expect(items[2]).toHaveTextContent(/^test 1$/)
    expect(items[3]).toHaveTextContent(/^search$/)
    expect(items[4]).toHaveTextContent(/^search123$/)

    await clearSearch()
    await typeInSearch('test 4')

    items = getAllByRole(view.getByTestId('lastSearches'), 'listitem')
    expect(items).toHaveLength(5)
    expect(items[0]).toHaveTextContent(/^test 4$/)
    expect(items[4]).toHaveTextContent(/^search$/)

    await clearSearch()
    await typeInSearch('search')

    items = getAllByRole(view.getByTestId('lastSearches'), 'listitem')
    expect(items).toHaveLength(5)
    expect(items[0]).toHaveTextContent(/^search$/)
  })

  it('clicking previous searches calls api', async () => {
    localStorage.clear()
    const view = await visitView('/search/user')

    const input = view.getByPlaceholderText('Search…')
    await view.events.debounced(() => view.events.type(input, 'search'))
    await view.events.debounced(() => view.events.type(input, '123'))

    await waitUntil(() => mockSearchApi.calls.resolve)

    const items = view.getAllByRole('listitem')
    expect(items).toHaveLength(2)
    expect(items[0]).toHaveTextContent('search123')
    expect(items[1]).toHaveTextContent('search')

    await view.events.debounced(() => view.events.click(items[1]))

    // :TODO check why this fails on ui works?
    // items = view.getAllByRole('listitem')
    // expect(items[0]).toHaveTextContent('search')
    // expect(items[1]).toHaveTextContent('search123')

    expect(mockSearchApi.spies.resolve).toHaveBeenNthCalledWith(1, {
      onlyIn: 'User',
      search: 'search',
      limit: 30,
    })
    expect(mockSearchApi.spies.resolve).toHaveBeenNthCalledWith(2, {
      onlyIn: 'User',
      search: 'search123',
      limit: 30,
    })
  })

  it('emptying out search shows last searches', async () => {
    localStorage.clear()
    clearMockClient()
    mockSearchApi.willResolve({
      search: [
        nullableMock({
          __typename: 'User',
          id: '1sdsada',
          internalId: 1,
          updatedAt: new Date().toISOString(),
          firstname: 'Max',
          lastname: 'Mustermann',
        }),
      ],
    })
    const view = await visitView('/search/user')

    const input = view.getByPlaceholderText('Search…')
    await view.events.debounced(() => view.events.type(input, 'search'))
    await view.events.debounced(() => view.events.type(input, '123'))

    await waitUntil(() => mockSearchApi.calls.resolve)

    expect(view.container).toHaveTextContent('Max Mustermann')

    await view.events.debounced(() => view.events.clear(input))

    expect(view.container).not.toHaveTextContent('Max Mustermann')

    expect(view.getByTestId('lastSearches')).toBeInTheDocument()
  })

  it('shows last searches, when opening page', async () => {
    localStorage.clear()
    localStorage.setItem(
      'lastSearches',
      JSON.stringify(['search', 'search123']),
    )
    const view = await visitView('/search/user')

    expect(view.getByRole('button', { name: 'search' })).toBeInTheDocument()
    expect(view.getByRole('button', { name: 'search123' })).toBeInTheDocument()

    const input = view.getByPlaceholderText('Search…')
    await view.events.debounced(() => view.events.type(input, 'search55'), 100)

    await view.events.clear(input)

    expect(
      view.queryByRole('button', { name: 'search55' }),
    ).not.toBeInTheDocument()
  })
})
