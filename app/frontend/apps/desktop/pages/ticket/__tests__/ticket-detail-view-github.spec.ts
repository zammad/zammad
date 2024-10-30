// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/
import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import getUuid from '#shared/utils/getUuid.ts'

import { mockTicketExternalReferencesIssueTrackerItemListQuery } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIssueTrackerList.mocks.ts'

describe('Ticket detail view GitHub integration', () => {
  it('displays GitHub integration on ticket detail page', async () => {
    mockPermissions(['ticket.agent'])

    await mockApplicationConfig({
      github_integration: true,
    })

    const ticket = createDummyTicket()

    mockTicketQuery({ ticket })

    const view = await visitView('/tickets/1')

    const sidebar = view.getByLabelText('Content sidebar')

    expect(
      within(sidebar).getByRole('button', { name: 'GitHub' }),
    ).toBeInTheDocument()
  })

  it('displays GitHub integration on ticket create page', async () => {
    mockPermissions(['ticket.agent'])

    await mockApplicationConfig({
      github_integration: true,
    })

    const uid = getUuid()
    const view = await visitView(`/ticket/create/${uid}`)

    const sidebar = view.getByLabelText('Content sidebar')

    expect(
      within(sidebar).getByRole('button', { name: 'GitHub' }),
    ).toBeInTheDocument()
  })

  it('hides GitHub integration when not available on ticket create screen', async () => {
    mockPermissions(['ticket.agent'])

    await mockApplicationConfig({
      github_integration: false,
    })

    const uid = getUuid()
    const view = await visitView(`/ticket/create/${uid}`)

    const sidebar = view.getByLabelText('Content sidebar')

    expect(
      within(sidebar).queryByRole('button', { name: 'GitHub' }),
    ).not.toBeInTheDocument()
  })

  it('hides GitHub integration when not available on ticket detail screen', async () => {
    mockPermissions(['ticket.agent'])

    await mockApplicationConfig({
      github_integration: false,
    })

    const ticket = createDummyTicket()

    mockTicketQuery({ ticket })

    mockTicketExternalReferencesIssueTrackerItemListQuery({
      ticketExternalReferencesIssueTrackerItemList: [],
    })

    const view = await visitView('/tickets/1')

    const sidebar = view.getByLabelText('Content sidebar')

    expect(
      within(sidebar).queryByRole('button', { name: 'GitHub' }),
    ).not.toBeInTheDocument()
  })
})
