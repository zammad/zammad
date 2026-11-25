// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import { mockDetailSearchQuery } from '#desktop/components/Search/graphql/queries/detailSearch.mocks.ts'

const copyToClipboardMock = vi.fn()

vi.mock('#shared/composables/useCopyToClipboard.ts', async (importOriginal) => ({
  ...(await importOriginal<typeof import('#shared/composables/useCopyToClipboard.ts')>()),
  useCopyToClipboard: () => ({ copyToClipboard: copyToClipboardMock }),
}))

const visitSearch = async () => {
  const view = await visitView('/search/test')

  const table = await view.findByRole('table', { name: 'Search result for: Ticket' })

  await waitFor(() => expect(within(table).getAllByTestId('table-row')).toHaveLength(2))

  return {
    view,
    rows: within(table).getAllByTestId('table-row'),
    searchField: within(view.getByTestId('search-container')).getByRole('searchbox', {
      name: 'Search…',
    }),
  }
}

describe('search view keyboard navigation', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])

    mockDetailSearchQuery({
      search: {
        totalCount: 2,
        items: [
          createDummyTicket({ ticketId: '1', title: 'Ticket 1' }),
          createDummyTicket({ ticketId: '2', title: 'Ticket 2' }),
        ],
      },
    })
  })

  it('copies the search term, then with the link via the period shortcut', async () => {
    mockApplicationConfig({ fqdn: 'zammad.example.com', http_type: 'https' })

    const { view, rows } = await visitSearch()

    rows[0].focus()
    copyToClipboardMock.mockClear()

    await view.events.keyboard('...')

    const url = 'https://zammad.example.com/desktop/search/test?entity=Ticket'

    expect(copyToClipboardMock).toHaveBeenCalledTimes(2)
    expect(copyToClipboardMock).toHaveBeenNthCalledWith(1, 'test')
    expect(copyToClipboardMock).toHaveBeenNthCalledWith(2, [
      {
        data: {
          'text/html': `<a href="${url}">test</a>`,
          'text/plain': `test\n${url}`,
        },
        options: {
          presentationStyle: 'unspecified',
        },
      },
    ])
  })

  it('leaves a period typed into the search field to the field', async () => {
    const { view, searchField } = await visitSearch()

    searchField.focus()
    copyToClipboardMock.mockClear()

    await view.events.keyboard('...')

    expect(copyToClipboardMock).not.toHaveBeenCalled()
  })

  it('goes down from the search field to the results and back up from the first one', async () => {
    const { view, rows, searchField } = await visitSearch()

    searchField.focus()
    await view.events.keyboard('{ArrowDown}')
    expect(rows[0]).toHaveFocus()

    await view.events.keyboard('{ArrowDown}')
    expect(rows[1]).toHaveFocus()

    await view.events.keyboard('{ArrowUp}{ArrowUp}')

    await waitFor(() => expect(searchField).toHaveFocus())
  })

  it('goes down from an entity tab to the results', async () => {
    const { view, rows } = await visitSearch()

    view.getByRole('tab', { name: /Ticket/ }).focus()
    await view.events.keyboard('{ArrowDown}')

    expect(rows[0]).toHaveFocus()
  })
})
