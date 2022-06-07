// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { getByText, getAllByRole } from '@testing-library/vue'
import { visitView } from '@tests/support/components/visitView'

describe('testing previous searches block', () => {
  it('previous searches', async () => {
    localStorage.clear()
    const view = await visitView('/search/user')

    const getByTextInLastSearch = (text: string) => {
      return getByText(view.getByTestId('lastSearches'), text)
    }

    const typeInSearch = (text: string) => {
      return view.events.debounced(() =>
        view.events.type(view.getByPlaceholderText('Search'), text),
      )
    }
    const clearSearch = () => {
      return view.events.debounced(() =>
        view.events.clear(view.getByPlaceholderText('Search')),
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

    const input = view.getByPlaceholderText('Search')
    await view.events.debounced(() => view.events.type(input, 'search'))
    await view.events.debounced(() => view.events.type(input, '123'))

    let items = view.getAllByRole('listitem')
    expect(items).toHaveLength(2)
    expect(items[0]).toHaveTextContent(/^search123$/)
    expect(items[1]).toHaveTextContent(/^search$/)

    await view.events.debounced(() => view.events.click(items[1]))

    items = view.getAllByRole('listitem')
    expect(items[0]).toHaveTextContent(/^search$/)
    expect(items[1]).toHaveTextContent(/^search123$/)

    // TODO expect api called
  })
})
