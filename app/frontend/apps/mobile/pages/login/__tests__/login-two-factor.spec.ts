// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import {
  mockPublicLinks,
  mockPublicLinksSubscription,
} from '#shared/entities/public-links/__tests__/mocks/mockPublicLinks.ts'
import { LoginDocument } from '#shared/graphql/mutations/login.api.ts'
import { EnumTwoFactorMethod } from '#shared/graphql/types.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockGraphQLApi } from '#tests/support/mock-graphql-api.ts'

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

    mockGraphQLApi(LoginDocument).willResolve({
      login: {
        session: null,
        errors: null,
        twoFactorRequired: {
          availableTwoFactorMethods: [EnumTwoFactorMethod.AuthenticatorApp],
          defaultTwoFactorMethod: EnumTwoFactorMethod.AuthenticatorApp,
        },
      },
    })

    const view = await visitView('/login')

    expect(view.queryByTestId('loginThirdParty')).toBeInTheDocument()

    const loginInput = view.getByPlaceholderText('Username / Email')
    const passwordInput = view.getByPlaceholderText('Password')

    await view.events.type(loginInput, 'admin@example.com')
    await view.events.type(passwordInput, 'wrong')

    await view.events.click(view.getByText('Sign in'))

    expect(view.queryByLabelText('Security Code')).toBeInTheDocument()
    expect(view.queryByTestId('loginThirdParty')).not.toBeInTheDocument()
  })
})
