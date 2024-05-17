// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { faker } from '@faker-js/faker'
import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'

import type { TwoFactorActionTypes } from '#shared/entities/two-factor/types.ts'
import { EnumTwoFactorAuthenticationMethod } from '#shared/graphql/types.ts'

import {
  mockUserCurrentPasswordCheckMutation,
  waitForUserCurrentPasswordCheckMutationCalls,
} from '#desktop/entities/user/current/graphql/mutations/userCurrentPasswordCheck.mocks.ts'
import { getUserCurrentTwoFactorUpdatesSubscriptionHandler } from '#desktop/entities/user/current/graphql/subscriptions/userCurrentTwoFactorUpdates.mocks.ts'

interface AuthenticatorApp {
  type: 'authenticatorApp'
  configured: boolean
  action?: TwoFactorActionTypes
}

interface SecurityKeys {
  type: 'securityKeys'
  configured: boolean
  action?: TwoFactorActionTypes
}

type Configuration = AuthenticatorApp | SecurityKeys

export const visitViewAndMockPasswordConfirmation = async (
  recoveryCodesExist: boolean,
  configuration: Configuration,
  flyoutHeading = /Set up Two-factor Authentication: Confirm Password/i,
) => {
  // Set up the configuration
  const enabledAuthenticationMethods: {
    authenticationMethod: EnumTwoFactorAuthenticationMethod
    configured: boolean
  }[] = []

  if (configuration.type === 'authenticatorApp') {
    enabledAuthenticationMethods.push({
      authenticationMethod: EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
      configured: configuration.configured,
    })
  }

  if (configuration.type === 'securityKeys') {
    enabledAuthenticationMethods.push({
      authenticationMethod: EnumTwoFactorAuthenticationMethod.SecurityKeys,
      configured: configuration.configured,
    })
  }

  const view = await visitView('/personal-setting/two-factor-auth')

  await getUserCurrentTwoFactorUpdatesSubscriptionHandler().trigger({
    userCurrentTwoFactorUpdates: {
      configuration: {
        enabledAuthenticationMethods,
        recoveryCodesExist,
      },
    },
  })

  // Open flyout on the specified view
  if (configuration?.type === 'authenticatorApp') {
    switch (configuration.action) {
      case 'edit':
        await view.events.click(
          view.getByRole('button', {
            name: 'Action menu button for authenticator app',
          }),
        )
        await view.events.click(view.getByRole('button', { name: 'Edit' }))
        break
      case 'remove':
        await view.events.click(
          view.getByRole('button', {
            name: 'Action menu button for authenticator app',
          }),
        )
        await view.events.click(
          view.getByRole('button', {
            name: 'Remove',
          }),
        )
        break
      case 'setup':
      default:
        await view.events.click(
          view.getByRole('button', { name: 'Set up authenticator app' }),
        )
    }
  }

  if (configuration?.type === 'securityKeys') {
    switch (configuration?.action) {
      case 'edit':
        await view.events.click(
          view.getByRole('button', { name: 'Edit security keys' }),
        )
        break
      case 'remove':
        await view.events.click(
          view.getByRole('button', { name: 'Remove security keys' }),
        )
        break
      case 'setup':
      default:
        await view.events.click(
          view.getByRole('button', { name: 'Set up security keys' }),
        )
    }
  }

  const flyout = await view.findByRole('complementary', {
    name: flyoutHeading,
  })

  const flyoutContent = within(flyout)

  const passwordInput = flyoutContent.getByLabelText('Current password')

  await view.events.type(
    passwordInput,
    faker.number.binary({ min: 10000, max: 99999 }).toString(),
  )

  mockUserCurrentPasswordCheckMutation({
    userCurrentPasswordCheck: {
      success: true,
    },
  })

  const buttonLabel = configuration.action === 'remove' ? 'Remove' : 'Next'

  await view.events.click(view.getByRole('button', { name: buttonLabel }))

  await waitForUserCurrentPasswordCheckMutationCalls()

  return {
    view,
    flyout,
    flyoutContent,
    passwordInput,
  }
}
