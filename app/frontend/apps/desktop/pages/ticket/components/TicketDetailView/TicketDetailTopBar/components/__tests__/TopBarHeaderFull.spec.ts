// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { provideTicketInformationMocks } from '#desktop/entities/ticket/__tests__/mocks/provideTicketInformationMocks.ts'
import { testOptionsTopBar } from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/__tests__/support/testOptions.ts'
import TopBarHeaderFull from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/components/TopBarHeaderFull.vue'

const copyToClipboardMock = vi.fn()

vi.mock('#shared/composables/useCopyToClipboard.ts', async () => ({
  useCopyToClipboard: () => ({ copyToClipboard: copyToClipboardMock }),
}))

const renderTopBarHeaderFull = ({
  ticket = testOptionsTopBar,
}: {
  ticket?: typeof testOptionsTopBar
} = {}) => {
  return renderComponent(
    {
      components: { TopBarHeaderFull },
      setup() {
        provideTicketInformationMocks(ticket)
      },
      template: '<TopBarHeaderFull />',
    },
    { form: true, router: true },
  )
}

describe('TopBarHeaderFull', () => {
  beforeEach(() => {
    copyToClipboardMock.mockReset()

    mockApplicationConfig({
      fqdn: 'zammad.example.com',
      http_type: 'http',
      ticket_hook: 'Ticket#',
    })
  })

  it('shows breadcrumb and copy button', () => {
    const view = renderTopBarHeaderFull()

    expect(view.getByText('Tickets')).toBeInTheDocument()
    expect(view.getByText('Ticket#89001')).toBeInTheDocument()
    expect(view.getByRole('button', { name: 'Copy ticket number' })).toBeInTheDocument()
  })

  it('shows highlight actions for editable agent tickets', () => {
    const view = renderTopBarHeaderFull()

    expect(view.getByRole('button', { name: 'Highlight options' })).toBeInTheDocument()
  })

  it('hides highlight actions for readonly tickets', () => {
    const view = renderTopBarHeaderFull({
      ticket: {
        ...testOptionsTopBar,
        policy: { ...testOptionsTopBar.policy, update: false },
      },
    })

    expect(view.queryByRole('button', { name: 'Highlight options' })).not.toBeInTheDocument()
  })

  it('copies ticket number with desktop link', async () => {
    const view = renderTopBarHeaderFull()

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

  it('renders flex-col on narrow container', () => {
    const view = renderTopBarHeaderFull()
    const avatar = view.getAllByTestId('common-avatar')[0]
    let container = avatar.parentElement

    while (container && !container.classList.contains('flex-col')) {
      container = container.parentElement
    }

    expect(container).not.toBeNull()
    expect(container).toHaveClass('flex-col')
  })

  it('renders @5xl:flex-row on wide container', () => {
    const view = renderTopBarHeaderFull()
    const avatar = view.getAllByTestId('common-avatar')[0]
    let container = avatar.parentElement

    while (container && !container.classList.contains('flex-col')) {
      container = container.parentElement
    }

    expect(container).not.toBeNull()
    expect(container).toHaveClass('@5xl:flex-row')
  })
})
