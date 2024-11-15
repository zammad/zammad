// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/
import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import { mockTicketExternalReferencesIssueTrackerItemListQuery } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIssueTrackerList.mocks.ts'

describe('Ticket detail view - GitLab integration', () => {
  it('displays sidebar', async () => {
    mockPermissions(['ticket.agent'])

    await mockApplicationConfig({
      gitlab_integration: true,
    })

    mockTicketQuery({
      ticket: createDummyTicket(),
    })

    const view = await visitView('/tickets/1')

    const sidebar = view.getByLabelText('Content sidebar')

    expect(
      within(sidebar).getByRole('button', { name: 'GitLab' }),
    ).toBeInTheDocument()
  })

  it('hides sidebar when not available', async () => {
    mockPermissions(['ticket.agent'])

    mockTicketExternalReferencesIssueTrackerItemListQuery({
      ticketExternalReferencesIssueTrackerItemList: [],
    })

    await mockApplicationConfig({
      gitlab_integration: false,
    })

    mockTicketQuery({
      ticket: createDummyTicket(),
    })

    const view = await visitView('/tickets/1')

    const sidebar = view.getByLabelText('Content sidebar')

    expect(
      within(sidebar).queryByRole('button', { name: 'GitLab' }),
    ).not.toBeInTheDocument()
  })
})
