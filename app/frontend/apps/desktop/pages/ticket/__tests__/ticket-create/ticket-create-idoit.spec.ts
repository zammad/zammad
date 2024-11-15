// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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
import { mockTicketExternalReferencesIdoitObjectListQuery } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIdoitObjectList.mocks.ts'
import { mockTicketExternalReferencesIdoitObjectSearchQuery } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIdoitObjectSearch.mocks.ts'

describe('Ticket create i-doit links', () => {
  describe('ticket creation', () => {
    it('submits a new ticket with i-doit objects', async () => {
      await mockApplicationConfig({
        idoit_integration: true,
        ui_task_mananger_max_task_count: 30,
        ui_ticket_create_available_types: [
          'phone-in',
          'phone-out',
          'email-out',
        ],
      })
      mockPermissions(['ticket.agent'])
      handleMockFormUpdaterQuery({
        pending_time: {
          show: false,
        },
      })

      mockTicketExternalReferencesIdoitObjectListQuery({
        ticketExternalReferencesIdoitObjectList: [],
      })
      const uid = getUuid()

      const view = await visitView(`/ticket/create/${uid}`)

      await view.events.click(view.getByRole('button', { name: 'i-doit' }))

      await waitFor(() =>
        expect(
          view.getByRole('heading', { level: 1, name: 'New Ticket' }),
        ).toBeInTheDocument(),
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

      mockTicketExternalReferencesIdoitObjectSearchQuery({
        ticketExternalReferencesIdoitObjectSearch: [
          {
            idoitObjectId: 26,
            link: 'http://localhost:9001/?objID=26',
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
        name: 'i-doit: Link objects',
      })

      await view.events.click(await within(flyout).findByText('26'))

      await view.events.click(
        within(flyout).getByRole('button', { name: 'Link Objects' }),
      )

      await view.events.click(view.getByRole('button', { name: 'Create' }))

      const calls = await waitForTicketCreateMutationCalls()
      expect(calls.at(-1)?.variables.input).toEqual(
        expect.objectContaining({
          externalReferences: {
            idoit: expect.anything(), // :TODO automock does not returns the right [26] id instead a random generated object ids
          },
        }),
      )
    })
  })

  it('displays i-doit integration', async () => {
    mockApplicationConfig({
      idoit_integration: true,
    })
    mockPermissions(['ticket.agent'])

    const uid = getUuid()
    const view = await visitView(`/ticket/create/${uid}`)

    const sidebar = view.getByLabelText('Content sidebar')

    expect(
      within(sidebar).getByRole('button', { name: 'i-doit' }),
    ).toBeInTheDocument()
  })

  it('hides i-doit integration when not available', async () => {
    mockPermissions(['ticket.agent'])

    mockApplicationConfig({
      idoit_integration: false,
    })

    const uid = getUuid()
    const view = await visitView(`/ticket/create/${uid}`)

    const sidebar = view.getByLabelText('Content sidebar')

    expect(
      within(sidebar).queryByRole('button', { name: 'i-doit' }),
    ).not.toBeInTheDocument()
  })
})
