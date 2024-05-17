// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockGraphQLApi } from '#tests/support/mock-graphql-api.ts'

import {
  mockPublicLinks,
  mockPublicLinksSubscription,
} from '#shared/entities/public-links/__tests__/mocks/mockPublicLinks.ts'
import { LoginDocument } from '#shared/graphql/mutations/login.api.ts'
import { EnumTwoFactorAuthenticationMethod } from '#shared/graphql/types.ts'

describe('testing login error handling', () => {
  beforeEach(() => {
    mockPublicLinks([])
    mockPublicLinksSubscription()
    mockApplicationConfig({ product_name: 'Zammad' })
  })

  it('check required login fields', async () => {
    const view = await visitView('/login')
    await view.events.click(view.getByText('Sign in'))

    expect(view.getByLabelText('Username / Email')).toBeDescribedBy(
      'This field is required.',
    )

    expect(view.getByLabelText('Password')).toBeDescribedBy(
      'This field is required.',
    )
  })

  it('check that login request error is visible', async () => {
    mockGraphQLApi(LoginDocument).willFailWithUserError({
      login: {
        session: null,
        errors: [
          {
            message:
              'Login failed. Have you double-checked your credentials and completed the email verification step?',
          },
        ],
        twoFactorRequired: null,
      },
    })

    const view = await visitView('/login')

    const loginInput = view.getByPlaceholderText('Username / Email')
    const passwordInput = view.getByPlaceholderText('Password')

    await view.events.type(loginInput, 'admin@example.com')
    await view.events.type(passwordInput, 'wrong')

    await view.events.click(view.getByText('Sign in'))

    expect(view.getByTestId('notification')).toBeInTheDocument()
    expect(view.getByTestId('notification')).toHaveTextContent(
      'Login failed. Have you double-checked your credentials and completed the email verification step?',
    )
  })

  it('check that two factor request error is visible', async () => {
    mockGraphQLApi(LoginDocument).willResolve([
      {
        login: {
          session: null,
          errors: null,
          twoFactorRequired: {
            availableTwoFactorAuthenticationMethods: [
              EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
            ],
            defaultTwoFactorAuthenticationMethod:
              EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
            recoveryCodesAvailable: false,
          },
        },
      },
      {
        login: {
          session: null,
          errors: [
            {
              message:
                'Login failed. Please double-check your two-factor authentication method.',
            },
          ],
          twoFactorRequired: null,
        },
      },
    ])

    const view = await visitView('/login')

    const loginInput = view.getByPlaceholderText('Username / Email')
    const passwordInput = view.getByPlaceholderText('Password')

    await view.events.type(loginInput, 'admin@example.com')
    await view.events.type(passwordInput, 'wrong')

    await view.events.click(view.getByText('Sign in'))

    await view.events.type(view.getByLabelText('Security Code'), '123456')

    await view.events.click(view.getByText('Sign in'))

    expect(view.getByTestId('notification')).toBeInTheDocument()
    expect(view.getByTestId('notification')).toHaveTextContent(
      'Login failed. Please double-check your two-factor authentication method.',
    )
  })
})
