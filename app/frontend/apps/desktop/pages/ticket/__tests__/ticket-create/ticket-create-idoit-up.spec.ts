// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'
import { expect } from 'vitest'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { waitForTicketCreateMutationCalls } from '#shared/entities/ticket/graphql/mutations/create.mocks.ts'
import getUuid from '#shared/utils/getUuid.ts'

import {
  handleCustomerMock,
  handleMockFormUpdaterQuery,
  handleMockUserQuery,
} from '#desktop/pages/ticket/__tests__/support/ticket-create-helpers.ts'
import { mockTicketExternalReferencesIdoitUpObjectListQuery } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIdoitUpObjectList.mocks.ts'
import { mockTicketExternalReferencesIdoitUpObjectSearchQuery } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIdoitUpObjectSearch.mocks.ts'

describe('Ticket create i-doit up links', () => {
  describe('ticket creation', () => {
    it.todo('submits a new ticket with i-doit up objects', async () => {
      mockApplicationConfig({
        idoit_up_integration: true,
        ui_task_mananger_max_task_count: 30,
        ui_ticket_create_available_types: ['phone-in', 'phone-out', 'email-out'],
      })
      mockPermissions(['ticket.agent'])
      handleMockFormUpdaterQuery({
        pending_time: {
          show: false,
        },
      })

      mockTicketExternalReferencesIdoitUpObjectListQuery({
        ticketExternalReferencesIdoitUpObjectList: [],
      })
      const uid = getUuid()

      const view = await visitView(`/ticket/create/${uid}`)

      await view.events.click(view.getByRole('button', { name: 'i-doit up' }))

      await waitFor(() =>
        expect(view.getByRole('heading', { level: 1, name: 'New ticket' })).toBeInTheDocument(),
      )

      await view.events.type(view.getByLabelText('Title'), 'Test Ticket')

      await handleCustomerMock(view)

      handleMockUserQuery()

      await view.events.click(
        view.getByRole('option', {
          name: 'Avatar (Nicole Braun) Nicole Braun – Zammad Foundation',
        }),
      )

      await view.events.click(view.getByLabelText('Text'))
      await view.events.type(view.getByLabelText('Text'), 'Test ticket text')

      await view.events.click(view.getByLabelText('Group'))
      await view.events.click(view.getByRole('option', { name: 'Users' }))

      await view.events.click(view.getByLabelText('Priority'))
      await view.events.click(view.getByRole('option', { name: '2 normal' }))

      await view.events.click(view.getByLabelText('State'))
      await view.events.click(view.getByRole('option', { name: 'open' }))

      const sidebar = view.getByLabelText('Content sidebar')

      mockTicketExternalReferencesIdoitUpObjectSearchQuery({
        ticketExternalReferencesIdoitUpObjectSearch: [
          {
            idoitUpObjectId: '00000000Test0026',
            link: 'http://localhost:9001/object/00000000Test0026',
            title: 'Test',
            type: 'Building',
            status: 'in operation',
          },
        ],
      })

      await view.events.click(
        await within(sidebar).findByRole('button', {
          name: 'Link Objects',
        }),
      )

      const flyout = await view.findByRole('complementary', {
        name: 'i-doit up: Link objects',
      })

      await view.events.click(await within(flyout).findByText('00000000Test0026'))

      await view.events.click(within(flyout).getByRole('button', { name: 'Link Objects' }))

      await view.events.click(view.getByRole('button', { name: 'Create' }))

      // :TODO FIXME
      const calls = await waitForTicketCreateMutationCalls()
      expect(calls.at(-1)?.variables.input).toEqual(
        expect.objectContaining({
          externalReferences: {
            idoitUp: expect.anything(), // :TODO automock does not returns the right ['00000000Test0026'] id instead a random generated object ids
          },
        }),
      )
    })
  })

  it('displays i-doit up integration', async () => {
    mockApplicationConfig({
      idoit_up_integration: true,
    })
    mockPermissions(['ticket.agent'])

    const uid = getUuid()
    const view = await visitView(`/ticket/create/${uid}`)

    const sidebar = view.getByLabelText('Content sidebar')

    expect(within(sidebar).getByRole('button', { name: 'i-doit up' })).toBeInTheDocument()
  })

  it('hides i-doit up integration when not available', async () => {
    mockPermissions(['ticket.agent'])

    mockApplicationConfig({
      idoit_up_integration: false,
    })

    const uid = getUuid()
    const view = await visitView(`/ticket/create/${uid}`)

    const sidebar = view.getByLabelText('Content sidebar')

    expect(within(sidebar).queryByRole('button', { name: 'i-doit up' })).not.toBeInTheDocument()
  })
})
