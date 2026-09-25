// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { waitForFormUpdaterQueryCalls } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { waitForTicketCreateMutationCalls } from '#shared/entities/ticket/graphql/mutations/create.mocks.ts'
import getUuid from '#shared/utils/getUuid.ts'

import { handleMockFormUpdaterQuery } from '../support/ticket-create-helpers.ts'

const phone = '+49 30 609812345'

// The form updater seeds the customer field from the query, so the mock answers like it does.
const mockFormUpdaterWithPhone = () =>
  handleMockFormUpdaterQuery({
    customer_id: { value: phone, options: [{ value: phone, label: phone }] },
  })

const visitCreateViewForNumber = () =>
  visitView(`/tickets/create/${getUuid()}?customer_phone=${encodeURIComponent(phone)}`)

describe('ticket create view - opened for an unknown caller', () => {
  beforeEach(() => {
    mockApplicationConfig({
      ui_ticket_create_available_types: ['phone-in', 'phone-out', 'email-out'],
    })
    mockPermissions(['ticket.agent'])
  })

  it('hands the number to the form updater and shows it as the customer', async () => {
    mockFormUpdaterWithPhone()

    const view = await visitCreateViewForNumber()

    const calls = await waitForFormUpdaterQueryCalls()

    expect(calls.at(-1)?.variables).toEqual(
      expect.objectContaining({
        meta: expect.objectContaining({
          initial: true,
          additionalData: expect.objectContaining({ customer_phone: phone }),
        }),
      }),
    )

    expect(await view.findByLabelText('Customer')).toHaveTextContent(phone)
  })

  it('creates the ticket with the number as the customer', async () => {
    mockFormUpdaterWithPhone()

    const view = await visitCreateViewForNumber()

    await view.events.type(await view.findByLabelText('Title'), 'Call from an unknown number')
    await view.events.type(
      view.getByRole('textbox', { name: 'Text' }),
      'The caller asked for a quote.',
    )

    await view.events.click(view.getByLabelText('Group'))
    await view.events.click(view.getByRole('option', { name: 'Users' }))

    await view.events.click(view.getByRole('button', { name: 'Create' }))

    const calls = await waitForTicketCreateMutationCalls()

    expect(calls.at(-1)?.variables.input).toEqual(expect.objectContaining({ customer: { phone } }))
  })
})
