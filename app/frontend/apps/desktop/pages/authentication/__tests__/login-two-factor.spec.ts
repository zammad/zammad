// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  mockGraphQLResult,
  waitForGraphQLMockCalls,
} from '#tests/graphql/builders/mocks.ts'
import type { ExtendedRenderResult } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { LoginDocument } from '#shared/graphql/mutations/login.api.ts'
import {
  EnumTwoFactorAuthenticationMethod,
  type LoginMutation,
} from '#shared/graphql/types.ts'

const twoFactorAuthentication = () => ({
  availableTwoFactorAuthenticationMethods: [
    EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
  ],
  defaultTwoFactorAuthenticationMethod:
    EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
  recoveryCodesAvailable: false,
})

const visitLogin = async (login?: Partial<LoginMutation['login']>) => {
  mockGraphQLResult<LoginMutation>(LoginDocument, {
    login: {
      session: null,
      errors: null,
      twoFactorRequired: twoFactorAuthentication(),
      ...login,
    },
  })

  return visitView('/login')
}

const login = async (view: ExtendedRenderResult) => {
  const loginInput = view.getByLabelText('Username / Email')
  const passwordInput = view.getByLabelText('Password')

  await view.events.type(loginInput, 'admin@example.com')
  await view.events.type(passwordInput, 'wrong')

  await view.events.click(view.getByText('Sign in'))

  await waitForGraphQLMockCalls('mutation', 'login')

  return view
}

describe('two-factor login flow', () => {
  it('does not show third party auth on two factor page', async () => {
    mockApplicationConfig({
      user_show_password_login: true,
      product_name: 'Zammad',
      auth_facebook: true,
      auth_twitter: true,
    })

    const view = await visitLogin({
      twoFactorRequired: {
        ...twoFactorAuthentication(),
        recoveryCodesAvailable: true,
      },
    })

    expect(view.queryByTestId('loginThirdParty')).toBeInTheDocument()

    await login(view)

    expect(view.queryByLabelText('Security Code')).toBeInTheDocument()
    expect(view.queryByTestId('loginThirdParty')).not.toBeInTheDocument()
  })

  it('has cancel button that resets the flow', async () => {
    mockApplicationConfig({
      user_show_password_login: true,
      product_name: 'Zammad',
      auth_facebook: true,
      auth_twitter: true,
    })

    const view = await visitLogin({
      twoFactorRequired: {
        ...twoFactorAuthentication(),
        recoveryCodesAvailable: true,
      },
    })

    expect(
      view.queryByRole('button', { name: 'Cancel & Go Back' }),
    ).not.toBeInTheDocument()

    await login(view)

    expect(
      view.queryByRole('button', { name: 'Cancel & Go Back' }),
    ).not.toBeInTheDocument()

    await view.events.click(view.getByText('Try another method'))

    expect(
      view.getByRole('button', { name: 'Cancel & Go Back' }),
    ).toBeInTheDocument()

    await view.events.click(
      view.getByText('Or use one of your recovery codes.'),
    )

    expect(view.getByLabelText('Recovery Code')).toBeInTheDocument()

    await view.events.click(view.getByText('Try another method'))

    await view.events.click(
      view.getByRole('button', { name: 'Cancel & Go Back' }),
    )

    expect(view.getByLabelText('Username / Email')).toBeInTheDocument()
    expect(view.getByLabelText('Password')).toBeInTheDocument()

    expect(
      view.queryByRole('button', { name: 'Cancel & Go Back' }),
    ).not.toBeInTheDocument()
  })

  describe('alternative two-factor methods', () => {
    it.each([
      {
        availableTwoFactorAuthenticationMethods: [
          EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
        ],
        defaultTwoFactorAuthenticationMethod:
          EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
        recoveryCodesAvailable: false,
        name: 'does not show up when only one method is available and recovery is disabled',
        available: false,
      },
      {
        availableTwoFactorAuthenticationMethods: [
          EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
        ],
        defaultTwoFactorAuthenticationMethod:
          EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
        recoveryCodesAvailable: true,
        name: 'shows up when only one method is available and recovery is enabled',
        available: true,
      },
      {
        availableTwoFactorAuthenticationMethods: [
          EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
          EnumTwoFactorAuthenticationMethod.SecurityKeys,
        ],
        defaultTwoFactorAuthenticationMethod:
          EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
        recoveryCodesAvailable: false,
        name: 'shows up when multiple methods are available and recovery is disabled',
        available: true,
      },
    ])('$name', async ({ available, ...scenario }) => {
      const view = await visitLogin({
        twoFactorRequired: scenario,
      })

      await login(view)

      if (available) {
        expect(view.getByText('Try another method')).toBeInTheDocument()
      } else {
        expect(view.queryByText('Try another method')).not.toBeInTheDocument()
      }
    })
  })
})
