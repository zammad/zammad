// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { beforeEach, describe, expect } from 'vitest'
import { ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { provideTicketInformationMocks } from '#desktop/entities/ticket/__tests__/mocks/provideTicketInformationMocks.ts'
import { testOptionsTopBar } from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/__tests__/support/testOptions.ts'
import TicketDetailTopBar from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TicketDetailTopBar.vue'
import { mockChecklistTemplatesQuery } from '#desktop/pages/ticket/graphql/queries/checklistTemplates.mocks.ts'

const copyToClipboardMock = vi.fn()

vi.mock('#shared/composables/useCopyToClipboard.ts', async () => ({
  useCopyToClipboard: () => ({ copyToClipboard: copyToClipboardMock }),
}))

vi.mock('#desktop/pages/ticket/composables/useTicketSidebar.ts')

const renderTopBar = (
  // eslint-disable-next-line default-param-last
  options = testOptionsTopBar,
  props?: { hideDetails: boolean },
) => {
  return renderComponent(
    {
      components: { TicketDetailTopBar },
      setup() {
        provideTicketInformationMocks(options)
        const hideDetails = ref(!!props?.hideDetails)
        return { hideDetails }
      },
      template: `<div ref="parent"><TicketDetailTopBar :hide-details="hideDetails"  /></div>`,
    },
    { form: true, router: true },
  )
}
describe('TicketDetailTopBar', () => {
  beforeEach(() => {
    mockApplicationConfig({
      ticket_hook: 'Ticket#',
    })
    mockChecklistTemplatesQuery({
      checklistTemplates: [],
    })
  })

  it('shows breadcrumb with copyable ticket number', () => {
    const wrapper = renderTopBar()

    expect(wrapper.getByText('Ticket#89001')).toBeInTheDocument()
  })

  it('hides details on scroll', () => {
    const wrapper = renderTopBar(testOptionsTopBar, { hideDetails: true })

    expect(wrapper.getByText('Welcome to Zammad!')).toBeInTheDocument()
    expect(wrapper.queryByText('Nicole Braun')).not.toBeInTheDocument()
    expect(wrapper.queryByText('Zammad Foundation')).not.toBeInTheDocument()
    expect(wrapper.queryByText('Highlight')).not.toBeInTheDocument()
  })

  it('shows infos about the ticket', () => {
    const wrapper = renderTopBar()

    expect(wrapper.getByText('Welcome to Zammad!')).toBeInTheDocument()
    expect(wrapper.getByText('Nicole Braun')).toBeInTheDocument()
    expect(wrapper.getByText('Zammad Foundation')).toBeInTheDocument()
    expect(wrapper.getByText('Welcome to Zammad!')).toBeInTheDocument()
    expect(wrapper.getByText('Highlight')).toBeInTheDocument()
  })

  describe('features', () => {
    it('copies ticket number', async () => {
      const wrapper = renderTopBar()

      await wrapper.events.click(wrapper.getByIconName('files'))

      expect(copyToClipboardMock).toHaveBeenCalledWith('Ticket#89001')
    })

    it('shows highlight menu', () => {
      const wrapper = renderTopBar()

      expect(wrapper.getByText('Highlight')).toBeInTheDocument()
      expect(wrapper.getByIconName('highlighter')).toBeInTheDocument()
    })
  })

  it('displays in readonly mode if update permission is not granted', () => {
    const readOnlyOptions = { ...testOptionsTopBar }
    testOptionsTopBar.policy.update = false

    const wrapper = renderTopBar(readOnlyOptions)

    expect(wrapper.queryByText('Highlight')).not.toBeInTheDocument()
    expect(
      wrapper.queryByRole('button', { name: 'Welcome to Zammad!' }),
    ).not.toBeInTheDocument()

    expect(
      wrapper.getByRole('heading', { name: 'Welcome to Zammad!', level: 2 }),
    ).toBeInTheDocument()
  })
})
