// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { waitForUserCurrentTwoFactorRemoveMethodMutationCalls } from '#shared/entities/user/current/graphql/mutations/two-factor/userCurrentTwoFactorRemoveMethod.mocks.ts'
import { waitForUserCurrentTwoFactorSetDefaultMethodMutationCalls } from '#shared/entities/user/current/graphql/mutations/two-factor/userCurrentTwoFactorSetDefaultMethod.mocks.ts'
import { EnumTwoFactorAuthenticationMethod } from '#shared/graphql/types.ts'

import { getUserCurrentTwoFactorUpdatesSubscriptionHandler } from '#desktop/entities/user/current/graphql/subscriptions/userCurrentTwoFactorUpdates.mocks.ts'
import { visitViewAndMockPasswordConfirmation } from '#desktop/pages/personal-setting/__tests__/support/personal-setting-two-factor-auth.ts'

describe('password personal settings', () => {
  it('redirects to the error page when two factor security is disabled', async () => {
    await mockApplicationConfig({
      two_factor_authentication_method_authenticator_app: false,
    })

    const view = await visitView('/personal-setting/two-factor-auth')

    await vi.waitFor(() => {
      expect(view, 'correctly redirects to error page').toHaveCurrentUrl(
        '/error-tab',
      )
    })
  })

  describe('authentication methods', () => {
    beforeEach(async () => {
      await mockApplicationConfig({
        two_factor_authentication_method_security_keys: true,
        two_factor_authentication_method_authenticator_app: true,
      })
    })

    it('renders ui with authentication apps', async () => {
      const view = await visitView('/personal-setting/two-factor-auth')

      expect(view.getByText('Authenticator App')).toBeInTheDocument()
      expect(
        view.getByText(
          'Get the security code from the authenticator app on your device.',
        ),
      ).toBeInTheDocument()

      expect(view.getByText('Security Keys')).toBeInTheDocument()
      expect(
        view.getByText('Complete the sign-in with your security key.'),
      ).toBeInTheDocument()
    })

    describe('authenticator app', () => {
      it('set up', async () => {
        const { flyoutContent } = await visitViewAndMockPasswordConfirmation(
          false,
          {
            type: 'authenticatorApp',
            configured: false,
            action: 'setup',
          },
        )
        expect(
          flyoutContent.getByText(
            'Set Up Two-factor Authentication: Authenticator App',
          ),
        ).toBeInTheDocument()
      })

      it('removal', async () => {
        const { flyout } = await visitViewAndMockPasswordConfirmation(
          true,
          {
            type: 'authenticatorApp',
            configured: true,
            action: 'remove',
          },
          /Remove Two-factor Authentication: Confirm Password/i,
        )

        const calls =
          await waitForUserCurrentTwoFactorRemoveMethodMutationCalls()

        expect(calls.at(-1)?.variables).toEqual(
          expect.objectContaining({
            methodName: 'authenticator_app',
          }),
        )

        expect(flyout).not.toBeInTheDocument()
      })

      it('edit', async () => {
        const { flyoutContent } = await visitViewAndMockPasswordConfirmation(
          false,
          {
            type: 'authenticatorApp',
            configured: true,
            action: 'edit',
          },
        )
        expect(
          flyoutContent.getByText(
            'Set Up Two-factor Authentication: Authenticator App',
          ),
        ).toBeInTheDocument()
      })

      it('set as default', async () => {
        const view = await visitView('/personal-setting/two-factor-auth')

        await getUserCurrentTwoFactorUpdatesSubscriptionHandler().trigger({
          userCurrentTwoFactorUpdates: {
            configuration: {
              enabledAuthenticationMethods: [
                {
                  authenticationMethod:
                    EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
                  configured: true,
                },
                {
                  authenticationMethod:
                    EnumTwoFactorAuthenticationMethod.SecurityKeys,
                  configured: true,
                },
              ],
            },
          },
        })

        await view.events.click(
          view.getByRole('button', {
            name: 'Action menu button for security keys',
          }),
        )

        await view.events.click(
          view.getByRole('button', { name: 'Set as default' }),
        )

        const calls =
          await waitForUserCurrentTwoFactorSetDefaultMethodMutationCalls()

        expect(calls.at(-1)?.variables).toEqual({ methodName: 'security_keys' })
      })
    })
  })
})
