// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { provideTicketInformationMocks } from '#desktop/entities/ticket/__tests__/mocks/provideTicketInformationMocks.ts'
import { testOptionsTopBar } from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/__tests__/support/testOptions.ts'
import TopBarHeaderCompact from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/components/TopBarHeaderCompact.vue'

const renderTopBarHeaderCompact = ({
  ticket = testOptionsTopBar,
}: {
  ticket?: typeof testOptionsTopBar
} = {}) => {
  return renderComponent(
    {
      components: { TopBarHeaderCompact },
      setup() {
        provideTicketInformationMocks(ticket)
      },
      template: '<TopBarHeaderCompact />',
    },
    { form: true, router: true },
  )
}

const TICKET_HOOK = 'Ticket#'

describe('TopBarHeaderCompact', () => {
  beforeEach(() => {
    mockApplicationConfig({
      fqdn: 'zammad.example.com',
      http_type: 'http',
      ticket_hook: TICKET_HOOK,
    })
  })

  it('shows last part of breadcrumb and copy button', () => {
    const view = renderTopBarHeaderCompact()

    expect(
      view.getByRole('heading', { name: `${TICKET_HOOK}${testOptionsTopBar.number}` }),
    ).toBeInTheDocument()
    expect(view.getByRole('button', { name: 'Copy ticket number' })).toBeInTheDocument()
  })

  it('shows highlight actions for editable agent tickets', () => {
    const view = renderTopBarHeaderCompact()

    expect(view.getByRole('button', { name: 'Highlight options' })).toBeInTheDocument()
  })

  it('hides highlight actions for readonly tickets', () => {
    const view = renderTopBarHeaderCompact({
      ticket: {
        ...testOptionsTopBar,
        policy: { ...testOptionsTopBar.policy, update: false },
      },
    })

    expect(view.queryByRole('button', { name: 'Highlight options' })).not.toBeInTheDocument()
  })
})
