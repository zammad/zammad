// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { ExtendedRenderResult } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockGraphQLApi } from '#tests/support/mock-graphql-api.ts'

import {
  mockPublicLinks,
  mockPublicLinksSubscription,
} from '#shared/entities/public-links/__tests__/mocks/mockPublicLinks.ts'
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
  mockGraphQLApi(LoginDocument).willResolve({
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
  const loginInput = view.getByPlaceholderText('Username / Email')
  const passwordInput = view.getByPlaceholderText('Password')

  await view.events.type(loginInput, 'admin@example.com')
  await view.events.type(passwordInput, 'wrong')

  await view.events.click(view.getByText('Sign in'))

  return view
}

describe('two factor login flow', () => {
  beforeEach(() => {
    mockPublicLinks([])
    mockPublicLinksSubscription()
  })

  it("don't show third party on two factor page", async () => {
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

  it('back button works correctly', async () => {
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

    expect(view.queryByLabelText('Go back')).not.toBeInTheDocument()

    await login(view)

    expect(view.getByLabelText('Go back')).toBeInTheDocument()

    await view.events.click(
      view.getByRole('button', { name: 'Try another method' }),
    )

    expect(view.getByLabelText('Go back')).toBeInTheDocument()

    await view.events.click(
      view.getByRole('button', { name: 'Or use one of your recovery codes.' }),
    )

    expect(view.getByLabelText('Recovery Code')).toBeInTheDocument()

    await view.events.click(view.getByLabelText('Go back'))

    expect(
      view.getByRole('button', { name: 'Or use one of your recovery codes.' }),
    ).toBeInTheDocument()

    await view.events.click(view.getByLabelText('Go back'))

    expect(view.queryByLabelText('Security Code')).toBeInTheDocument()

    await view.events.click(view.getByLabelText('Go back'))

    expect(view.queryByLabelText('Security Code')).not.toBeInTheDocument()
    expect(view.getByPlaceholderText('Username / Email')).toBeInTheDocument()
    expect(view.queryByLabelText('Go back')).not.toBeInTheDocument()
  })

  describe('show "try another method"', () => {
    it.each([
      {
        availableTwoFactorAuthenticationMethods: [
          EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
        ],
        defaultTwoFactorAuthenticationMethod:
          EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
        recoveryCodesAvailable: false,
        name: "can't see when only one method is available and recovery is disabled",
        available: false,
      },
      {
        availableTwoFactorAuthenticationMethods: [
          EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
        ],
        defaultTwoFactorAuthenticationMethod:
          EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
        recoveryCodesAvailable: true,
        name: 'can see when only one method is available and recovery is enabled',
        available: true,
      },
      // TODO 2023-05-29 Sheremet V.A. when several methods are implemented
      // {
      //   availableTwoFactorAuthenticationMethods: [
      //     EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
      //     'some_unknown_method',
      //   ],
      //   defaultTwoFactorAuthenticationMethod:
      //     EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
      //   recoveryCodesAvailable: false,
      //   name: 'can see when mutiple methods are available and recovery is disabled',
      //   available: true,
      // },
    ])('$name', async ({ available, ...scenario }) => {
      const view = await visitLogin({
        twoFactorRequired: scenario,
      })

      await login(view)

      if (available) {
        expect(
          view.queryByRole('button', { name: 'Try another method' }),
        ).toBeInTheDocument()
      } else {
        expect(
          view.queryByRole('button', { name: 'Try another method' }),
        ).not.toBeInTheDocument()
      }
    })
  })
})
