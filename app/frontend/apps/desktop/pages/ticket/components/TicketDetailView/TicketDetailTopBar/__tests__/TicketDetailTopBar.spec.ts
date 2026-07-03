// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { EnumChannelArea } from '#shared/graphql/types.ts'

import { provideTicketInformationMocks } from '#desktop/entities/ticket/__tests__/mocks/provideTicketInformationMocks.ts'
import { testOptionsTopBar } from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/__tests__/support/testOptions.ts'
import TicketDetailTopBar from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TicketDetailTopBar.vue'

const withChannelAlert = (
  overrides: Partial<typeof testOptionsTopBar> = {},
): typeof testOptionsTopBar => ({
  ...testOptionsTopBar,
  initialChannel: EnumChannelArea.WhatsAppBusiness,
  preferences: {
    whatsapp: {
      // Far enough in the past for the WhatsApp channel plugin to report the service window as
      // closed - a fixed "danger" alert with no relative-time placeholder, so assertions stay
      // deterministic.
      timestamp_incoming: Math.floor(Date.now() / 1000) - 48 * 3600,
    },
  },
  ...overrides,
})

const renderTicketDetailTopBar = ({
  ticket = testOptionsTopBar,
  contentContainerElement = null,
}: {
  ticket?: typeof testOptionsTopBar
  contentContainerElement?: HTMLDivElement | null
} = {}) => {
  return renderComponent(
    {
      components: { TicketDetailTopBar },
      setup() {
        provideTicketInformationMocks(ticket)
        return { contentContainerElement }
      },
      template: '<TicketDetailTopBar :content-container-element="contentContainerElement" />',
    },
    { form: true, router: true },
  )
}

describe('TicketDetailTopBar', () => {
  beforeEach(() => {
    mockApplicationConfig({
      fqdn: 'zammad.example.com',
      http_type: 'http',
      ticket_hook: 'Ticket#',
    })
  })

  it('renders the compact and full headers without a channel alert by default', () => {
    const view = renderTicketDetailTopBar()

    expect(view.getByTestId('ticket-detail-top-bar-clipped-details')).toBeInTheDocument()
    expect(view.getByTestId('ticket-detail-top-bar-full-details')).toBeInTheDocument()
    expect(view.queryByTestId('common-alert')).not.toBeInTheDocument()
  })

  it('wraps both headers with a channel alert for an editable agent ticket that has one', () => {
    const view = renderTicketDetailTopBar({ ticket: withChannelAlert() })

    const alerts = view.getAllByRole('alert')

    expect(alerts).toHaveLength(2)
    alerts.forEach((alert) => {
      expect(alert).toHaveTextContent(
        'The 24 hour customer service window is now closed, no further WhatsApp messages can be sent.',
      )
    })
  })

  it('does not wrap the headers with a channel alert when the ticket is not agent-visible', () => {
    const ticket = withChannelAlert({
      policy: { ...testOptionsTopBar.policy, agentReadAccess: false },
    })

    const view = renderTicketDetailTopBar({ ticket })

    expect(view.queryByTestId('common-alert')).not.toBeInTheDocument()
    expect(view.getByTestId('ticket-detail-top-bar-clipped-details')).toBeInTheDocument()
    expect(view.getByTestId('ticket-detail-top-bar-full-details')).toBeInTheDocument()
  })

  it('does not wrap the headers with a channel alert when the ticket is not editable', () => {
    const ticket = withChannelAlert({
      policy: { ...testOptionsTopBar.policy, update: false },
    })

    const view = renderTicketDetailTopBar({ ticket })

    expect(view.queryByTestId('common-alert')).not.toBeInTheDocument()
    expect(view.getByTestId('ticket-detail-top-bar-clipped-details')).toBeInTheDocument()
    expect(view.getByTestId('ticket-detail-top-bar-full-details')).toBeInTheDocument()
  })
})
