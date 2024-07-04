// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect } from 'vitest'
import { computed, provide, ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { MAIN_LAYOUT_KEY } from '#desktop/components/layout/composables/useMainLayoutContainer.ts'
import { testOptionsTopBar } from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/__tests__/support/testOptions.ts'
import TicketDetailTopBar from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TicketDetailTopBar.vue'
import { TICKET_INFORMATINO_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

const renderTopBar = () => {
  return renderComponent(
    {
      components: { TicketDetailTopBar },
      template: `<div ref="parent"><TicketDetailTopBar internal-id="1"/></div>`,
      setup() {
        const parent = ref<HTMLElement>()
        const parentContainer = computed(() => parent.value)

        provide(
          MAIN_LAYOUT_KEY,
          computed(() => parentContainer.value),
        )

        provide(
          TICKET_INFORMATINO_KEY,
          computed(() => testOptionsTopBar),
        )
        return {}
      },
    },
    { form: true },
  )
}
describe('TicketDetailTopBar', () => {
  beforeEach(() => {
    mockApplicationConfig({
      ticket_hook: 'ticket#test',
    })
  })

  it('shows breadcrumb with copyable ticket number', () => {
    const wrapper = renderTopBar()

    expect(wrapper.getByText('ticket#test89001')).toBeInTheDocument()
  })

  it.todo('hides details on scroll', () => {
    //   :TODO write this in cypress when available for desktop
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
      const copyLegacy = vi.fn()

      // vueUse executes here the `legacyCopy` function instead of window.navigator.clipboard.writeText
      // It does not exist on the global object, so we need to define it
      Object.defineProperty(document, 'execCommand', {
        value: () => copyLegacy('89001'),
        writable: true,
        configurable: true,
      })

      userEvent.setup({ writeToClipboard: true })

      const wrapper = renderTopBar()

      await wrapper.events.click(wrapper.getByIconName('clipboard2'))

      expect(copyLegacy).toHaveBeenCalledWith('89001')
    })

    it('shows highlight menu', () => {
      const wrapper = renderTopBar()

      expect(wrapper.getByText('Highlight')).toBeInTheDocument()
      expect(wrapper.getByIconName('highlighter')).toBeInTheDocument()
    })
  })
})
