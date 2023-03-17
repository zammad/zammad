// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { TicketOverviewsDocument } from '@shared/entities/ticket/graphql/queries/ticket/overviews.api'
import { getAllByTestId, getByTestId, within } from '@testing-library/vue'
import createMockClient from '@tests/support/mock-apollo-client'
import { visitView } from '@tests/support/components/visitView'
import {
  NotificationTypes,
  useNotifications,
} from '@shared/components/CommonNotifications'
import { mockAccount } from '@tests/support/mock-account'
import { getByIconName } from '@tests/support/components/iconQueries'
import { getApiTicketOverviews } from '@tests/support/mocks/ticket-overviews'
import { getTicketOverviewStorage } from '@mobile/entities/ticket/helpers/ticketOverviewStorage'

const actualLocalStorage = window.localStorage

describe('playing with overviews', () => {
  beforeEach(() => {
    mockAccount({ id: '666' })
    createMockClient([
      {
        operationDocument: TicketOverviewsDocument,
        handler: async () => ({ data: getApiTicketOverviews() }),
      },
    ])
  })

  afterEach(() => {
    window.localStorage = actualLocalStorage
    const { saveOverviews } = getTicketOverviewStorage()
    saveOverviews([])
  })

  it('loading overviews from local storage', async () => {
    const { saveOverviews, LOCAL_STORAGE_NAME } = getTicketOverviewStorage()
    saveOverviews(['1', '2'])

    const view = await visitView('/favorite/ticker-overviews/edit')

    const includedOverviewsUtils = within(
      await view.findByTestId('includedOverviews'),
    )

    const includedOverviews = await includedOverviewsUtils.findAllByTestId(
      'overviewItem',
    )

    expect(includedOverviews).toHaveLength(2)
    expect(includedOverviews[0]).toHaveTextContent('Overview 1')
    expect(includedOverviews[1]).toHaveTextContent('Overview 2')

    const excludedOverviewsUtils = within(
      await view.findByTestId('excludedOverviews'),
    )

    const excludedOverviews =
      excludedOverviewsUtils.getAllByTestId('overviewItem')

    expect(excludedOverviews).toHaveLength(1)
    expect(excludedOverviews[0]).toHaveTextContent('Overview 3')

    vi.stubGlobal('localStorage', {
      setItem: vi.fn(),
    })

    await view.events.click(view.getByText('Done'))

    expect(localStorage.setItem).toHaveBeenCalledWith(
      LOCAL_STORAGE_NAME,
      '["1","2"]',
    )
  })

  it('removing/adding overviews', async () => {
    const { LOCAL_STORAGE_NAME } = getTicketOverviewStorage()

    const view = await visitView('/favorite/ticker-overviews/edit')

    const buttonsRemove = await view.findAllByIconName('mobile-minus')

    expect(buttonsRemove).toHaveLength(3)

    const [overviewOneButton] = buttonsRemove

    await view.events.click(overviewOneButton)

    expect(view.getAllByIconName('mobile-minus')).toHaveLength(2)

    const overviewOneInExcluded = getByTestId(
      view.getByTestId('excludedOverviews'),
      'overviewItem',
    )

    expect(overviewOneInExcluded).toHaveTextContent('Overview 1')

    const buttonAdd = getByIconName(overviewOneInExcluded, 'mobile-plus')

    await view.events.click(buttonAdd)

    const includedOverviews = getAllByTestId(
      view.getByTestId('includedOverviews'),
      'overviewItem',
    )

    expect(includedOverviews.at(-1)).toHaveTextContent('Overview 1')

    vi.stubGlobal('localStorage', {
      setItem: vi.fn(),
    })

    await view.events.click(view.getByText('Done'))

    expect(localStorage.setItem).toHaveBeenCalledWith(
      LOCAL_STORAGE_NAME,
      '["2","3","1"]',
    )

    const { notify } = useNotifications()

    expect(notify).toHaveBeenCalledWith({
      type: NotificationTypes.Success,
      message: 'Ticket Overview settings are saved.',
    })
  })

  it('gives error, when trying to save no overviews', async () => {
    const { saveOverviews } = getTicketOverviewStorage()
    saveOverviews(['1'])
    const view = await visitView('/favorite/ticker-overviews/edit')

    const buttonRemove = await view.findByIconName('mobile-minus')

    await view.events.click(buttonRemove)
    await view.events.click(view.getByText('Done'))

    const { notify } = useNotifications()

    expect(notify).toHaveBeenCalledWith({
      type: NotificationTypes.Error,
      message: 'Please select at least one ticket overview',
    })
  })
})
