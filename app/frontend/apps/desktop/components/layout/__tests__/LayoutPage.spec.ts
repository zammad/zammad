// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import LayoutPage from '#desktop/components/layout/LayoutPage.vue'

import '#tests/graphql/builders/mocks.ts'

describe('LayoutPage', () => {
  it('expands search and focus quick search input', async () => {
    const wrapper = renderComponent(LayoutPage, {
      router: true,
      form: true,
    })

    await wrapper.events.click(
      wrapper.getByRole('button', {
        name: 'Collapse sidebar',
      }),
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
    beforeAll(() => {
      Object.defineProperty(window, 'location', {
        value: {
          ...window.location,
          pathname: '/desktop',
          href: '/desktop',
        },
      })
    })

    beforeEach(() => {
      mockPermissions(['user_preferences.beta_ui_switch'])

      mockApplicationConfig({
        ui_desktop_beta_switch: true,
      })
    })

    it('shows the switch if the feature is enabled', async () => {
      const wrapper = renderComponent(LayoutPage, {
        router: true,
        form: true,
      })

      const toggle = wrapper.getByLabelText('New Beta UI')

      expect(toggle).toBeChecked()

      expect(window.location.href).toBe('/desktop')

      await wrapper.events.click(toggle)

      await waitFor(() => expect(window.location.href).toBe('/'))
    })

    it('hides the switch if the feature is disabled', async () => {
      mockApplicationConfig({
        ui_desktop_beta_switch: false,
      })

      const wrapper = renderComponent(LayoutPage, {
        router: true,
        form: true,
      })

      expect(wrapper.queryByLabelText('New Beta UI')).not.toBeInTheDocument()
    })

    it('hides the switch if the user has no permissions', async () => {
      mockPermissions(['ticket.customer'])

      const wrapper = renderComponent(LayoutPage, {
        router: true,
        form: true,
      })

      expect(wrapper.queryByLabelText('New Beta UI')).not.toBeInTheDocument()
    })

    it('hides the switch if the user has dismissed it', async () => {
      localStorage.setItem('beta-ui-switch-dismiss', 'true')

      const wrapper = renderComponent(LayoutPage, {
        router: true,
        form: true,
      })

      expect(wrapper.queryByLabelText('New Beta UI')).not.toBeInTheDocument()

      localStorage.removeItem('beta-ui-switch-dismiss')
    })

    it('dismisses the switch on demand', async () => {
      const wrapper = renderComponent(LayoutPage, {
        router: true,
        form: true,
      })

      const toggle = wrapper.getByLabelText('New Beta UI')

      const button = wrapper.getByRole('button', {
        name: 'Hide Beta UI switch',
      })

      await wrapper.events.click(button)

      expect(toggle).not.toBeInTheDocument()
      expect(button).not.toBeInTheDocument()
    })
  })
})
