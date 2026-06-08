// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import BetaUiFeedbackConsentDialog from '../BetaUiFeedbackConsentDialog.vue'

describe('BetaUiFeedbackConsentDialog.vue', () => {
  it('renders the feedback consent dialog', () => {
    const wrapper = renderComponent(BetaUiFeedbackConsentDialog, {
      dialog: true,
      form: true,
      router: true,
    })

    expect(wrapper.getByRole('dialog')).toBeInTheDocument()

    expect(
      wrapper.getByRole('heading', {
        level: 3,
        name: 'Want to join the BETA UI feedback program?',
      }),
    ).toBeInTheDocument()

    expect(wrapper.getByText('Help us shape the future of Zammad!')).toBeInTheDocument()
    expect(wrapper.getByRole('button', { name: 'Agree & join' })).toBeInTheDocument()
    expect(wrapper.getByRole('button', { name: 'Maybe later' })).toBeInTheDocument()
  })

  it.each([
    {
      name: 'Agree & join',
      value: 'true',
    },
    {
      name: 'Maybe later',
      value: 'false',
    },
  ])('writes $value to local storage when button $name is clicked', async ({ name, value }) => {
    const wrapper = renderComponent(BetaUiFeedbackConsentDialog, {
      dialog: true,
      form: true,
      router: true,
    })

    await wrapper.events.click(wrapper.getByRole('button', { name }))

    expect(localStorage.getItem('beta-ui-feedback-consent')).toBe(value)
  })
})
