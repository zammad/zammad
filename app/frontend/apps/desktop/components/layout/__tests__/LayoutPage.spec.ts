// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { navigateTo } from '#shared/utils/navigation.ts'

import LayoutPage from '#desktop/components/layout/LayoutPage.vue'

import '#tests/graphql/builders/mocks.ts'

vi.mock('#shared/server/apollo/client.ts', () => ({
  getApolloClient: () => ({
    cache: {
      readQuery: vi.fn(),
      writeQuery: vi.fn(),
    },
  }),
}))

vi.mock('#shared/utils/navigation.ts')

vi.mock(
  '#desktop/components/BetaUi/FeedbackDialog/useFeedbackDialog.ts',
  async (originalModule) => {
    const module =
      await originalModule<typeof import('#desktop/components/CommonDialog/useDialog.ts')>()

    return {
      ...module,
      useFeedbackDialog: () => ({
        openFeedbackDialog: ({ callback }: { callback: () => void }) => {
          callback()
        },
      }),
    }
  },
)

describe('LayoutPage', () => {
  afterEach(() => {
    localStorage.clear()
  })

  it('expands search and focus quick search input', async () => {
    const wrapper = renderComponent(LayoutPage, {
      router: true,
      form: true,
    })

    // one button has display none it's for smaller screens
    await wrapper.events.click(
      wrapper.getAllByRole('button', {
        name: 'Collapse sidebar',
      })[0],
    )

    expect(
      wrapper.queryByRole('searchbox', {
        name: 'Search…',
      }),
    ).not.toBeInTheDocument()

    await wrapper.events.click(
      wrapper.getByRole('button', {
        name: 'Open quick search',
      }),
    )

    await waitForNextTick()

    expect(
      wrapper.getByRole('searchbox', {
        name: 'Search…',
      }),
    ).toHaveFocus()
  })

  describe('Feature: Beta UI Switch', () => {
    beforeEach(() => {
      mockApplicationConfig({
        ui_desktop_beta_switch: true,
      })

      mockUserCurrent({
        hasBetaUiSwitchAvailable: true,
      })
    })

    it('shows the switch if the feature is enabled', async () => {
      const wrapper = renderComponent(LayoutPage, {
        router: true,
        form: true,
      })

      const toggle = wrapper.getByLabelText('BETA UI')

      expect(toggle).toBeChecked()

      await wrapper.events.click(toggle)

      await waitFor(() => expect(navigateTo).toHaveBeenCalledWith('/'))
    })

    it('hides the switch if the feature is disabled', async () => {
      mockApplicationConfig({
        ui_desktop_beta_switch: false,
      })

      const wrapper = renderComponent(LayoutPage, {
        router: true,
        form: true,
      })

      expect(wrapper.queryByLabelText('BETA UI')).not.toBeInTheDocument()
    })

    it('hides the switch if the user has no permissions', async () => {
      mockUserCurrent({
        hasBetaUiSwitchAvailable: false,
      })

      const wrapper = renderComponent(LayoutPage, {
        router: true,
        form: true,
      })

      expect(wrapper.queryByLabelText('BETA UI')).not.toBeInTheDocument()
    })

    it('hides the switch if the user has dismissed it', async () => {
      localStorage.setItem('beta-ui-switch-dismiss', 'true')

      const wrapper = renderComponent(LayoutPage, {
        router: true,
        form: true,
      })

      expect(wrapper.queryByLabelText('BETA UI')).not.toBeInTheDocument()

      localStorage.removeItem('beta-ui-switch-dismiss')
    })

    it('dismisses the switch on demand', async () => {
      const wrapper = renderComponent(LayoutPage, {
        router: true,
        form: true,
      })

      const toggle = wrapper.getByLabelText('BETA UI')

      const button = wrapper.getByRole('button', {
        name: 'Hide BETA UI switch',
      })

      await wrapper.events.click(button)

      expect(toggle).not.toBeInTheDocument()
      expect(button).not.toBeInTheDocument()
    })
  })
})
