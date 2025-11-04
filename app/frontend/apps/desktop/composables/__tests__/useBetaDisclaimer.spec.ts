// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { describe, it, beforeEach, expect, afterAll } from 'vitest'

import renderComponent, { initializePiniaStore } from '#tests/support/components/renderComponent.ts'

import { useAuthenticationStore } from '#shared/stores/authentication.ts'

import { useBetaDisclaimer } from '../useBetaDisclaimer.ts'

const DummyComponent = {
  template: '<div></div>',
  setup() {
    useBetaDisclaimer()
  },
}

describe('useDesktopViewWarning', () => {
  beforeEach(() => {
    localStorage.setItem('beta-ui-disclaimer', 'false')

    initializePiniaStore()
    useAuthenticationStore().authenticated = true
  })

  afterAll(() => {
    localStorage.removeItem('beta-ui-disclaimer')
  })

  it('opens dialog if not dismissed and confirms', async () => {
    const wrapper = renderComponent(DummyComponent, {
      router: true,
      store: true,
      dialog: true,
    })

    expect(await wrapper.findByText('New Desktop UI — Alpha Version')).toBeInTheDocument()
    expect(
      wrapper.getByText(
        'This new desktop UI is currently in development and not ready for production use. It may contain bugs or incomplete features.',
      ),
    ).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Confirm' }))

    expect(localStorage.getItem('beta-ui-disclaimer')).toBe('true')
  })

  it('does not open dialog if already dismissed', async () => {
    localStorage.setItem('beta-ui-disclaimer', 'true')

    const wrapper = renderComponent(DummyComponent, {
      router: true,
      store: true,
      dialog: true,
    })

    expect(wrapper.queryByRole('dialog')).not.toBeInTheDocument()
  })
})
