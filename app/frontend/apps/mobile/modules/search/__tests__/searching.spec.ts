// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '@tests/support/components/visitView'

describe('visiting search page', () => {
  // TODO 2022-06-02 Sheremet V.A. remove skip when there is an actual API
  it.skip('doesnt search if no type is selected', async () => {
    const view = await visitView('/search')

    const searchInput = view.getByPlaceholderText('Search')
    await view.events.type(searchInput, 'search')

    // TODO expect no api call
  })

  it('allows searching', async () => {
    const view = await visitView('/search')

    const searchInput = view.getByPlaceholderText('Search')

    expect(searchInput).toHaveFocus()
    expect(view.getByTestId('selectTypesSection')).toBeInTheDocument()

    await view.events.click(view.getByText('Users'))
    await view.events.type(searchInput, 'search')

    // TODO api called

    expect(view.getByTestId('buttonPills')).toBeInTheDocument()

    await view.events.click(view.getByText('Organizations'))

    // TODO api called immidiatly

    // expect(view.getByIconName('loader')).toBeInTheDocument()

    expect(view.getByPlaceholderText('Search')).toHaveFocus()
  })

  it('renders correctly if queries are passed done', async () => {
    const view = await visitView('/search/invalid?search=search')

    expect(view.getByPlaceholderText('Search')).toHaveDisplayValue('search')
    expect(view.getByTestId('selectTypesSection')).toBeInTheDocument()
  })
})
