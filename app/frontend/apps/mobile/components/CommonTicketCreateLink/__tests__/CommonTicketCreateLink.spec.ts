// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import CommonTicketCreateLink from '../CommonTicketCreateLink.vue'

describe('CommonTicketCreateLink', () => {
  it('shows the create link for agents when customer ticket create is enabled', () => {
    mockPermissions(['ticket.agent'])
    mockApplicationConfig({
      customer_ticket_create: true,
    })

    const view = renderComponent(CommonTicketCreateLink, {
      router: true,
      store: true,
    })

    const link = view.getByRole('link')
    expect(link).toHaveAttribute('aria-label', 'Create new ticket')
  })

  it('hides the create link for customer when customer ticket create is disabled', () => {
    mockPermissions(['ticket.customer'])
    mockApplicationConfig({
      customer_ticket_create: false,
    })

    const view = renderComponent(CommonTicketCreateLink, {
      router: true,
      store: true,
    })

    expect(view.queryByRole('link')).not.toBeInTheDocument()
  })
})
