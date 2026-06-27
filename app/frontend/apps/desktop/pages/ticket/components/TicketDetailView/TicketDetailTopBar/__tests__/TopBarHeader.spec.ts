// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { provideTicketInformationMocks } from '#desktop/entities/ticket/__tests__/mocks/provideTicketInformationMocks.ts'
import { testOptionsTopBar } from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/__tests__/support/testOptions.ts'
import TopBarHeader from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader.vue'

const copyToClipboardMock = vi.fn()

vi.mock('#shared/composables/useCopyToClipboard.ts', async () => ({
  useCopyToClipboard: () => ({ copyToClipboard: copyToClipboardMock }),
}))

const renderTopBarHeader = ({
  hideDetails = false,
  ticket = testOptionsTopBar,
}: {
  hideDetails?: boolean
  ticket?: typeof testOptionsTopBar
} = {}) => {
  return renderComponent(
    {
      components: { TopBarHeader },
      setup() {
        provideTicketInformationMocks(ticket)

        return { hideDetails }
      },
      template: '<TopBarHeader :hide-details="hideDetails" />',
    },
    { form: true, router: true },
  )
}

describe('TopBarHeader', () => {
  beforeEach(() => {
    copyToClipboardMock.mockReset()

    mockApplicationConfig({
      fqdn: 'zammad.example.com',
      http_type: 'http',
      ticket_hook: 'Ticket#',
    })
  })

  it('shows breadcrumb and copy button in detailed mode', () => {
    const view = renderTopBarHeader()

    expect(view.getByText('Tickets')).toBeInTheDocument()
    expect(view.getByText('Ticket#89001')).toBeInTheDocument()
    expect(view.getByIconName('files')).toBeInTheDocument()
  })

  it('hides breadcrumb and copy button in compact mode', () => {
    const view = renderTopBarHeader({ hideDetails: true })

    expect(view.queryByText('Tickets')).not.toBeInTheDocument()
    expect(view.queryByIconName('files')).not.toBeInTheDocument()
  })

  it('shows highlight actions for editable agent tickets', () => {
    const view = renderTopBarHeader()

    expect(view.getByRole('button', { name: 'Highlight options' })).toBeInTheDocument()
  })

  it('hides highlight actions for readonly tickets', () => {
    const view = renderTopBarHeader({
      ticket: {
        ...testOptionsTopBar,
        policy: { ...testOptionsTopBar.policy, update: false },
      },
    })

    expect(view.queryByRole('button', { name: 'Highlight options' })).not.toBeInTheDocument()
  })

  it('copies ticket number with desktop link', async () => {
    const view = renderTopBarHeader()

    await view.events.click(view.getByIconName('files'))

    expect(copyToClipboardMock).toHaveBeenCalledWith([
      {
        data: {
          'text/html': '<a href="http://zammad.example.com/desktop/tickets/1">Ticket#89001</a>',
          'text/plain': 'Ticket#89001',
        },
        options: {
          presentationStyle: 'unspecified',
        },
      },
    ])
  })

  it('renders flex-col on narrow container when hideDetails=false', () => {
    const view = renderTopBarHeader()
    const avatar = view.getAllByTestId('common-avatar')[0]
    let container = avatar.parentElement

    while (container && !container.classList.contains('flex-col')) {
      container = container.parentElement
    }

    expect(container).not.toBeNull()
    expect(container).toHaveClass('flex-col')
  })

  it('renders @3xl:flex-row on wide container when hideDetails=false', () => {
    const view = renderTopBarHeader()
    const avatar = view.getAllByTestId('common-avatar')[0]
    let container = avatar.parentElement

    while (container && !container.classList.contains('flex-col')) {
      container = container.parentElement
    }

    expect(container).not.toBeNull()
    expect(container).toHaveClass('@3xl:flex-row')
  })
})
