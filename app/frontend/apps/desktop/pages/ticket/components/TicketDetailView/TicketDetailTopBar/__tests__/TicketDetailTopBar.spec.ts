// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { EnumChannelArea } from '#shared/graphql/types.ts'
import { getAlertClasses } from '#shared/initializer/initializeAlertClasses.ts'

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

  it('bleeds the alert background across the full width of both headers', () => {
    const view = renderTicketDetailTopBar({ ticket: withChannelAlert() })

    // The alert itself is aligned with the header content, so its wrapper has to carry the variant
    // background in order for the stripe to reach both edges of the header.
    view.getAllByTestId('channel-alert-background').forEach((background) => {
      expect(background).toHaveClass(getAlertClasses().translucent!.danger)
    })
  })

  it('bleeds the warning background while the service window is still open', () => {
    const ticket = withChannelAlert({
      preferences: { whatsapp: { timestamp_incoming: Math.floor(Date.now() / 1000) - 3600 } },
    })

    const view = renderTicketDetailTopBar({ ticket })

    view.getAllByTestId('channel-alert-background').forEach((background) => {
      expect(background).toHaveClass(getAlertClasses().translucent!.warning)
    })
  })

  it('tints both stripes translucently over the blurred content', () => {
    const view = renderTicketDetailTopBar({ ticket: withChannelAlert() })

    // The tint comes from the translucent variant on the stripe itself, so that the blur is not
    // faded along with it - as it would be with an `opacity` on the whole element.
    view.getAllByTestId('channel-alert-background').forEach((background) => {
      expect(background).toHaveClass('backdrop-blur-2xs')
    })

    view.getAllByRole('alert').forEach((alert) => {
      expect(alert).toHaveClass('bg-transparent!')
    })
  })

  it('aligns the alert with the ticket title in both modes', () => {
    const view = renderTicketDetailTopBar({ ticket: withChannelAlert() })

    const fullHeader = view.getByTestId('ticket-detail-top-bar-full-details')
    const compactHeader = view.getByTestId('ticket-detail-top-bar-clipped-details')

    // Both stripes are centered on the middle column of their header grid, which holds the title -
    // 46.5rem in the full header, 48rem in the compact one - each widened by the 1.375rem gutter
    // the leading icon takes up, and pulled back by the same amount, so that the text lines up
    // with the title and the icon hangs into the avatar column.
    expect(within(fullHeader).getByRole('alert')).toHaveClass(
      'me-5.5',
      'max-w-[calc(46.5rem+1.375rem)]',
    )
    expect(within(compactHeader).getByRole('alert')).toHaveClass(
      'me-5.5',
      'max-w-[calc(var(--container-3xl)+1.375rem)]',
    )

    view.getAllByTestId('channel-alert-background').forEach((background) => {
      expect(background).toHaveClass('justify-center')
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
