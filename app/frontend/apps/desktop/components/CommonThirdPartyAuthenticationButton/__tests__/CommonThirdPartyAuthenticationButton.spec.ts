// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { expect } from 'vitest'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { setCSRFToken } from '#shared/server/apollo/utils/csrfToken.ts'

import CommonThirdPartyAuthenticationButton from '#desktop/components/CommonThirdPartyAuthenticationButton/CommonThirdPartyAuthenticationButton.vue'

const token = '12345'
const url = '/auth/github'

setCSRFToken(token)

describe('CommonThirdPartyAuthenticationButton', () => {
  it('renders with default prop values', () => {
    const view = renderComponent(CommonThirdPartyAuthenticationButton, {
      props: {
        url,
      },
    })

    expect(view.getByRole('form')).toHaveFormValues({
      authenticity_token: token,
    })
  })

  it('renders with prop values', () => {
    const view = renderComponent(CommonThirdPartyAuthenticationButton, {
      props: {
        buttonLabel: 'GitHub',
        buttonIcon: 'github',
        url,
      },
    })

    expect(view.getByLabelText('GitHub')).toBeInTheDocument()
    expect(view.getByIconName('github')).toBeInTheDocument()
  })

  it('supports default slot', () => {
    const view = renderComponent(CommonThirdPartyAuthenticationButton, {
      props: {
        url,
      },
      slots: {
        default: () => 'GitHub',
      },
    })

    expect(view.getByText('GitHub')).toBeInTheDocument()
  })
})
