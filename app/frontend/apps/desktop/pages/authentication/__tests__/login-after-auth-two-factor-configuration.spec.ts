// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { getByRole } from '@testing-library/vue'

import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockLogoutMutation } from '#shared/graphql/mutations/logout.mocks.ts'
import { EnumAfterAuthType } from '#shared/graphql/types.ts'

import { ensureAfterAuth } from '../after-auth/composable/useAfterAuthPlugins.ts'

const visitAfterAuthTwoFactorConfiguration = async () => {
  const view = await visitView('/login/after-auth')

  await ensureAfterAuth(getTestRouter(), {
    type: EnumAfterAuthType.TwoFactorConfiguration,
    data: { token: 'foobar' },
  })

  return view
}

describe('Login - After Auth - Two Factor Configuration', () => {
  describe('without the required permission', () => {
    it('shows an error and allows to log out', async () => {
      const view = await visitAfterAuthTwoFactorConfiguration()

      const main = view.getByRole('main')

      expect(getByRole(main, 'alert')).toHaveTextContent(
        "Two-factor authentication is required, but you don't have sufficient permissions to set it up. Please contact your administrator.",
      )

      const logoutButton = view.getByRole('button', {
        name: 'Cancel & Sign Out',
      })

      mockLogoutMutation({
        logout: {
          success: true,
          externalLogoutUrl: null,
        },
      })

      await view.events.click(logoutButton)

      await vi.waitFor(() => {
        expect(view, 'correctly redirects to login page').toHaveCurrentUrl(
          '/login',
        )
      })
    })
  })

  describe('with the required permission', () => {
    beforeEach(() => {
      mockPermissions(['user_preferences.two_factor_authentication'])
      mockApplicationConfig({
        two_factor_authentication_method_authenticator_app: true,
        two_factor_authentication_method_security_keys: true,
      })
    })

    it('shows a list of two-factor methods', async () => {
      const view = await visitAfterAuthTwoFactorConfiguration()

      expect(
        view.getByText('Set Up Two-factor Authentication'),
      ).toBeInTheDocument()

      expect(
        view.getByText(
          'You must protect your account with two-factor authentication.',
        ),
      ).toBeInTheDocument()

      expect(
        view.getByText(
          'Choose your preferred two-factor authentication method to set it up.',
        ),
      ).toBeInTheDocument()

      expect(
        view.getByRole('button', {
          name: 'Security Keys',
        }),
      ).toBeInTheDocument()

      expect(
        view.getByText('Complete the sign-in with your security key.'),
      ).toBeInTheDocument()

      const authenticatorAppButton = view.getByRole('button', {
        name: 'Authenticator App',
      })

      expect(
        view.getByText(
          'Get the security code from the authenticator app on your device.',
        ),
      ).toBeInTheDocument()

      await view.events.click(authenticatorAppButton)

      expect(
        view.getByText(
          'To set up Authenticator App for your account, follow the steps below:',
        ),
      ).toBeInTheDocument()

      expect(
        view.getByRole('button', {
          name: 'Set Up',
        }),
      ).toBeInTheDocument()

      const goBackButton = view.getByRole('button', {
        name: 'Go Back',
      })

      await view.events.click(goBackButton)

      expect(
        view.getByRole('button', {
          name: 'Authenticator App',
        }),
      ).toBeInTheDocument()

      const logoutButton = view.getByRole('button', {
        name: 'Cancel & Sign Out',
      })

      mockLogoutMutation({
        logout: {
          success: true,
          externalLogoutUrl: null,
        },
      })

      await view.events.click(logoutButton)

      await vi.waitFor(() => {
        expect(view, 'correctly redirects to login page').toHaveCurrentUrl(
          '/login',
        )
      })
    })
  })
})
