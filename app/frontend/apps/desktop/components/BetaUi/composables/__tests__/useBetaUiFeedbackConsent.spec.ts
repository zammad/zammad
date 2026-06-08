// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'

import renderComponent, { initializePiniaStore } from '#tests/support/components/renderComponent.ts'

import { useAuthenticationStore } from '#shared/stores/authentication.ts'

import {
  initializeBetaUiFeedbackConsentDialog,
  useBetaUiFeedbackConsent,
} from '../useBetaUiFeedbackConsent.ts'

const DummyComponent = {
  template: '<div></div>',
  setup() {
    initializeBetaUiFeedbackConsentDialog()

    useBetaUiFeedbackConsent()
  },
}

describe('useBetaUiFeedbackConsent', () => {
  beforeEach(() => {
    initializePiniaStore()
    useAuthenticationStore().authenticated = true
  })

  afterAll(() => {
    localStorage.removeItem('beta-ui-feedback-consent')
  })

  it('opens dialog if consent was not stated yet', async () => {
    localStorage.setItem('beta-ui-feedback-consent', 'null')

    const wrapper = renderComponent(DummyComponent, {
      dialog: true,
      form: true,
      router: true,
    })

    expect(await wrapper.findByRole('dialog')).toBeInTheDocument()
    expect(wrapper.getByText('Want to join the BETA UI feedback program?')).toBeVisible()
    expect(wrapper.getByText('Help us shape the future of Zammad!')).toBeVisible()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Agree & join' }))

    waitFor(() => {
      expect(localStorage.getItem('beta-ui-feedback-consent')).toBe('true')
    })
  })

  it.fails.each(['true', 'false'])(
    'does not open dialog if consent was already stated',
    async (consent) => {
      localStorage.setItem('beta-ui-feedback-consent', consent)

      const wrapper = renderComponent(DummyComponent, {
        dialog: true,
        form: true,
        router: true,
      })

      expect(await wrapper.findByRole('dialog')).toBeInTheDocument()
    },
  )
})
