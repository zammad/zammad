// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import { mockLinkListQuery } from '../../graphql/queries/linkList.mocks.ts'

describe('Ticket detail view - draft handling', () => {
  describe('when user is an agent', () => {
    beforeEach(() => {
      mockPermissions(['ticket.agent'])

      mockLinkListQuery({
        linkList: [],
      })
    })

    it('shows save as draft if it is enabled for group and user is agent', async () => {
      mockFormUpdaterQuery({
        formUpdater: {
          fields: {},
          flags: {
            hasSharedDraft: true,
          },
        },
      })

      mockTicketQuery({
        ticket: createDummyTicket(),
      })

      const view = await visitView('/tickets/1')

      const actionMenu = await view.findByLabelText(
        'Additional ticket edit actions',
      )

      await view.events.click(actionMenu)

      const menu = await view.findByRole('menu')

      expect(within(menu).getByText('Save as draft')).toBeInTheDocument()
    })
  })

  describe('when user is an customer', () => {
    beforeEach(() => {
      mockPermissions(['ticket.customer'])
    })

    it('shows no save as draft if it an customer', async () => {
      mockFormUpdaterQuery({
        formUpdater: {
          fields: {},
          flags: {
            hasSharedDraft: true,
          },
        },
      })

      mockTicketQuery({
        ticket: createDummyTicket({
          defaultPolicy: { update: true, agentReadAccess: false },
        }),
      })

      const view = await visitView('/tickets/1')

      expect(
        view.queryByLabelText('Additional ticket edit actions'),
      ).not.toBeInTheDocument()
    })
  })
})
