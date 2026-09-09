// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { within } from '@testing-library/vue'
import { flushPromises } from '@vue/test-utils'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import {
  mockFormUpdaterQuery,
  waitForFormUpdaterQueryCalls,
} from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import {
  mockTicketUpdateMutation,
  waitForTicketUpdateMutationCalls,
} from '#shared/entities/ticket/graphql/mutations/update.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumFormUpdaterId, EnumUserErrorException } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { clearTicketArticlesLoadedState } from '../composable/useTicketArticlesVariables.ts'

import '#tests/graphql/builders/mocks.ts'

const ticketEditFormUpdaterOptions = {
  formUpdater: {
    fields: {
      pending_time: { show: false },
    },
    flags: { newArticlePresent: false },
  },
}

const timeAccountingError = {
  ticketUpdate: {
    ticket: null,
    errors: [
      {
        message: 'The ticket time accounting condition is met.',
        exception: EnumUserErrorException.ServiceTicketUpdateValidatorTimeAccountingError,
      },
    ],
  },
}

// Adds an article and triggers the ticket update, which is rejected by the time accounting
//   validator, so the time accounting dialog is requested.
const addArticleAndSave = async (
  formUpdaterDefaults: Parameters<typeof mockFormUpdaterQuery>[0] = ticketEditFormUpdaterOptions,
) => {
  mockTicketQuery({
    ticket: createDummyTicket({
      defaultPolicy: { update: true, agentReadAccess: true },
    }),
  })
  mockFormUpdaterQuery(formUpdaterDefaults)

  const view = await visitView('/tickets/1', { mockApollo: false })

  await waitForFormUpdaterQueryCalls()
  await getNode('form-ticket-edit')?.settled

  await view.events.click(view.getByRole('button', { name: 'Add reply' }))
  await view.events.type(await view.findByLabelText('Text'), 'Testing')

  await getNode('form-ticket-edit')?.settled

  mockTicketUpdateMutation(timeAccountingError)

  await view.events.click(await view.findByRole('button', { name: 'Save' }))

  await waitForTicketUpdateMutationCalls()

  return view
}

describe('time accounting in the ticket detail view', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])
    clearTicketArticlesLoadedState()
  })

  it('accounts the entered time with the next ticket update', async () => {
    mockApplicationConfig({
      time_accounting: true,
      time_accounting_unit: 'hour',
    })

    const view = await addArticleAndSave()

    const dialog = await view.findByRole('dialog', { name: 'Time accounting' })

    const timeUnitField = await within(dialog).findByLabelText('Accounted time')

    expect(
      await within(dialog).findByText('hour(s)'),
      'shows the configured unit',
    ).toBeInTheDocument()
    expect(
      within(dialog).queryByLabelText('Activity type'),
      'no activity type without the feature',
    ).not.toBeInTheDocument()

    await view.events.type(timeUnitField, '4,5')

    await getNode('ticket-time-accounting')?.settled

    mockTicketUpdateMutation({
      ticketUpdate: {
        ticket: createDummyTicket(),
        errors: null,
      },
    })

    await view.events.click(within(dialog).getByRole('button', { name: 'Account time' }))

    const calls = await waitForTicketUpdateMutationCalls()

    expect(calls.at(-1)?.variables).toEqual(
      expect.objectContaining({
        input: expect.objectContaining({
          article: expect.objectContaining({
            body: expect.stringContaining('Testing'),
            timeUnit: 4.5,
          }),
        }),
      }),
    )

    expect(view.queryByRole('dialog', { name: 'Time accounting' })).not.toBeInTheDocument()
  })

  it('sends the selected activity type when time accounting types are enabled', async () => {
    mockApplicationConfig({
      time_accounting: true,
      time_accounting_types: true,
    })

    const view = await addArticleAndSave((variables) => {
      if (variables.formUpdaterId === EnumFormUpdaterId.FormUpdaterUpdaterTicketTimeAccounting) {
        return {
          formUpdater: {
            fields: {
              accounted_time_type_id: {
                options: [
                  { value: 1, label: 'None' },
                  { value: 2, label: 'Finance' },
                ],
              },
            },
          },
        }
      }

      return ticketEditFormUpdaterOptions
    })

    const dialog = await view.findByRole('dialog', { name: 'Time accounting' })

    await view.events.type(await within(dialog).findByLabelText('Accounted time'), '1')

    await view.events.click(within(dialog).getByLabelText('Activity type'))
    await view.events.click(await view.findByRole('option', { name: 'Finance' }))

    await getNode('ticket-time-accounting')?.settled

    mockTicketUpdateMutation({
      ticketUpdate: {
        ticket: createDummyTicket(),
        errors: null,
      },
    })

    await view.events.click(within(dialog).getByRole('button', { name: 'Account time' }))

    const calls = await waitForTicketUpdateMutationCalls()

    expect(calls.at(-1)?.variables).toEqual(
      expect.objectContaining({
        input: expect.objectContaining({
          article: expect.objectContaining({
            timeUnit: 1,
            accountedTimeTypeId: convertToGraphQLId('Ticket::TimeAccounting::Type', 2),
          }),
        }),
      }),
    )
  })

  it('skips the validator on the next ticket update when the dialog is skipped', async () => {
    mockApplicationConfig({
      time_accounting: true,
    })

    const view = await addArticleAndSave()

    const dialog = await view.findByRole('dialog', { name: 'Time accounting' })

    mockTicketUpdateMutation({
      ticketUpdate: {
        ticket: createDummyTicket(),
        errors: null,
      },
    })

    await view.events.click(within(dialog).getByRole('button', { name: 'Skip' }))

    const calls = await waitForTicketUpdateMutationCalls()

    expect(calls.at(-1)?.variables.meta?.skipValidators).toContain(
      EnumUserErrorException.ServiceTicketUpdateValidatorTimeAccountingError,
    )

    expect(view.queryByRole('dialog', { name: 'Time accounting' })).not.toBeInTheDocument()
  })

  it('abandons the ticket update when the dialog is cancelled', async () => {
    mockApplicationConfig({
      time_accounting: true,
    })

    const view = await addArticleAndSave()

    const dialog = await view.findByRole('dialog', { name: 'Time accounting' })

    const calls = await waitForTicketUpdateMutationCalls()

    await view.events.click(within(dialog).getByRole('button', { name: 'Cancel' }))
    await flushPromises()

    expect(view.queryByRole('dialog', { name: 'Time accounting' })).not.toBeInTheDocument()
    expect(calls, 'no further ticket update').toHaveLength(1)

    // The article is still there, so the agent can update the ticket again.
    expect(await view.findByRole('button', { name: 'Save' })).toBeInTheDocument()
  })

  it('abandons the ticket update when the dialog is dismissed', async () => {
    mockApplicationConfig({
      time_accounting: true,
    })

    const view = await addArticleAndSave()

    await view.findByRole('dialog', { name: 'Time accounting' })

    const calls = await waitForTicketUpdateMutationCalls()

    await view.events.keyboard('{Escape}')
    await flushPromises()

    expect(view.queryByRole('dialog', { name: 'Time accounting' })).not.toBeInTheDocument()
    expect(calls, 'no further ticket update').toHaveLength(1)

    // The article is still there, so the agent can update the ticket again.
    expect(await view.findByRole('button', { name: 'Save' })).toBeInTheDocument()
  })

  it('does not request time accounting when the validator does not object', async () => {
    mockApplicationConfig({
      time_accounting: true,
    })

    mockTicketQuery({
      ticket: createDummyTicket({
        defaultPolicy: { update: true, agentReadAccess: true },
      }),
    })
    mockFormUpdaterQuery(ticketEditFormUpdaterOptions)

    const view = await visitView('/tickets/1', { mockApollo: false })

    await waitForFormUpdaterQueryCalls()
    await getNode('form-ticket-edit')?.settled

    await view.events.click(view.getByRole('button', { name: 'Add reply' }))
    await view.events.type(await view.findByLabelText('Text'), 'Testing')

    await getNode('form-ticket-edit')?.settled

    mockTicketUpdateMutation({
      ticketUpdate: {
        ticket: createDummyTicket(),
        errors: null,
      },
    })

    await view.events.click(await view.findByRole('button', { name: 'Save' }))

    const calls = await waitForTicketUpdateMutationCalls()

    expect(calls.at(-1)?.variables.meta?.skipValidators).not.toContain(
      EnumUserErrorException.ServiceTicketUpdateValidatorTimeAccountingError,
    )

    expect(
      calls.at(-1)?.variables.meta?.skipValidators,
      'validators without a mobile UI stay skipped',
    ).toContain(EnumUserErrorException.ServiceTicketUpdateValidatorChecklistCompletedError)

    expect(view.queryByRole('dialog', { name: 'Time accounting' })).not.toBeInTheDocument()
  })
})
