// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockWebAuthnCreation } from '#tests/support/mock-webauthn.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import {
  mockUserCurrentTwoFactorGetMethodConfigurationQuery,
  waitForUserCurrentTwoFactorGetMethodConfigurationQueryCalls,
} from '#shared/entities/user/current/graphql/mutations/two-factor/userCurrentTwoFactorGetMethodConfiguration.mocks.ts'
import {
  mockUserCurrentTwoFactorRecoveryCodesGenerateMutation,
  waitForUserCurrentTwoFactorRecoveryCodesGenerateMutationCalls,
} from '#shared/entities/user/current/graphql/mutations/two-factor/userCurrentTwoFactorRecoveryCodesGenerate.mocks.ts'
import { mockUserCurrentTwoFactorVerifyMethodConfigurationMutation } from '#shared/entities/user/current/graphql/mutations/two-factor/userCurrentTwoFactorVerifyMethodConfiguration.mocks.ts'
import { EnumTwoFactorAuthenticationMethod } from '#shared/graphql/types.ts'

import {
  mockUserCurrentPasswordCheckMutation,
  waitForUserCurrentPasswordCheckMutationCalls,
} from '#desktop/entities/user/current/graphql/mutations/userCurrentPasswordCheck.mocks.ts'
import { getUserCurrentTwoFactorUpdatesSubscriptionHandler } from '#desktop/entities/user/current/graphql/subscriptions/userCurrentTwoFactorUpdates.mocks.ts'

const recoveryCodes = [
  'foo',
  'bar',
  'baz',
  'qux',
  'quux',
  'corge',
  'grault',
  'garply',
  'waldo',
  'fred',
]

const copyToClipboardMock = vi.fn()

vi.mock('#shared/composables/useCopyToClipboard.ts', async () => ({
  useCopyToClipboard: () => ({ copyToClipboard: copyToClipboardMock }),
}))

describe('Two-factor Authentication - Recovery Codes', () => {
  beforeEach(() => {
    mockApplicationConfig({
      two_factor_authentication_method_security_keys: true,
      two_factor_authentication_recovery_codes: true,
    })
  })

  it('supports (re)generating new recovery codes', async () => {
    const view = await visitView('/personal-setting/two-factor-auth')

    await getUserCurrentTwoFactorUpdatesSubscriptionHandler().trigger({
      userCurrentTwoFactorUpdates: {
        configuration: {
          enabledAuthenticationMethods: [
            {
              authenticationMethod: EnumTwoFactorAuthenticationMethod.SecurityKeys,
              configured: true,
            },
          ],
          recoveryCodesExist: true,
        },
      },
    })

    await view.events.click(view.getByRole('button', { name: 'Regenerate recovery codes' }))

    const flyout = await view.findByRole('complementary', {
      name: 'Generate recovery codes: Confirm password',
    })

    const flyoutContent = within(flyout)

    const passwordInput = flyoutContent.getByLabelText('Current password')

    mockUserCurrentPasswordCheckMutation({
      userCurrentPasswordCheck: {
        success: true,
      },
    })

    mockUserCurrentTwoFactorRecoveryCodesGenerateMutation({
      userCurrentTwoFactorRecoveryCodesGenerate: {
        recoveryCodes,
      },
    })

    mockWebAuthnCreation()

    await view.events.type(passwordInput, 'test')
    await view.events.click(view.getByRole('button', { name: 'Next' }))

    await waitForUserCurrentPasswordCheckMutationCalls()
    await waitForUserCurrentTwoFactorRecoveryCodesGenerateMutationCalls()

    expect(flyout).toHaveAccessibleName('Generate recovery codes: Save codes')

    expect(
      flyoutContent.getByText(
        'Please save your recovery codes listed below somewhere safe. You can use them to sign in if you lose access to another two-factor method:',
      ),
    ).toBeInTheDocument()

    expect(flyoutContent.getByTestId('recovery-codes')).toHaveTextContent(
      'foobarbazquxquuxcorgegraultgarplywaldofred',
    )
  })

  it('shows recovery codes generated in a previous step', async () => {
    vi.stubGlobal('isSecureContext', true)

    const view = await visitView('/personal-setting/two-factor-auth')

    const actionMenuButton = view.getByRole('button', {
      name: 'Set up security keys',
    })

    await view.events.click(actionMenuButton)

    const flyout = await view.findByRole('complementary', {
      name: 'Set up two-factor authentication: Confirm password',
    })

    const flyoutContent = within(flyout)

    const passwordInput = flyoutContent.getByLabelText('Current password')

    mockUserCurrentPasswordCheckMutation({
      userCurrentPasswordCheck: {
        success: true,
      },
    })

    mockUserCurrentTwoFactorGetMethodConfigurationQuery({
      userCurrentTwoFactorGetMethodConfiguration: null,
    })

    mockWebAuthnCreation()

    await view.events.type(passwordInput, 'test')
    await view.events.click(view.getByRole('button', { name: 'Next' }))

    await waitForUserCurrentPasswordCheckMutationCalls()
    await waitForUserCurrentTwoFactorGetMethodConfigurationQueryCalls()

    await view.events.click(view.getByRole('button', { name: 'Set up' }))

    const nicknameInput = flyoutContent.getByLabelText('Name for this security key')

    await view.events.type(nicknameInput, 'My key')

    mockUserCurrentTwoFactorVerifyMethodConfigurationMutation({
      userCurrentTwoFactorVerifyMethodConfiguration: {
        recoveryCodes,
      },
    })

    await view.events.click(view.getByRole('button', { name: 'Next' }))

    await waitFor(() =>
      expect(flyout).toHaveAccessibleName('Set up two-factor authentication: Save codes'),
    )

    expect(flyoutContent.getByTestId('recovery-codes')).toHaveTextContent(
      'foobarbazquxquuxcorgegraultgarplywaldofred',
    )
  })

  it('supports showing printing generated recovery codes', async () => {
    const view = await visitView('/personal-setting/two-factor-auth')

    await getUserCurrentTwoFactorUpdatesSubscriptionHandler().trigger({
      userCurrentTwoFactorUpdates: {
        configuration: {
          enabledAuthenticationMethods: [
            {
              authenticationMethod: EnumTwoFactorAuthenticationMethod.SecurityKeys,
              configured: true,
            },
          ],
          recoveryCodesExist: true,
        },
      },
    })

    await view.events.click(view.getByRole('button', { name: 'Regenerate recovery codes' }))

    const flyout = await view.findByRole('complementary', {
      name: 'Generate recovery codes: Confirm password',
    })

    const flyoutContent = within(flyout)

    const passwordInput = flyoutContent.getByLabelText('Current password')

    mockUserCurrentPasswordCheckMutation({
      userCurrentPasswordCheck: {
        success: true,
      },
    })

    mockUserCurrentTwoFactorRecoveryCodesGenerateMutation({
      userCurrentTwoFactorRecoveryCodesGenerate: {
        recoveryCodes,
      },
    })

    await view.events.type(passwordInput, 'test')
    await view.events.click(view.getByRole('button', { name: 'Next' }))

    await waitForUserCurrentPasswordCheckMutationCalls()
    await waitForUserCurrentTwoFactorRecoveryCodesGenerateMutationCalls()

    const printArea = flyoutContent.getByTestId('print-area')

    expect(printArea).toHaveClass('print-area')

    Object.defineProperty(window, 'print', {
      value: vi.fn(),
    })

    await view.events.click(view.getByRole('button', { name: 'Print codes' }))

    expect(window.print).toHaveBeenCalledOnce()
  })

  it('supports copying generated recovery codes to clipboard', async () => {
    const view = await visitView('/personal-setting/two-factor-auth')

    await getUserCurrentTwoFactorUpdatesSubscriptionHandler().trigger({
      userCurrentTwoFactorUpdates: {
        configuration: {
          enabledAuthenticationMethods: [
            {
              authenticationMethod: EnumTwoFactorAuthenticationMethod.SecurityKeys,
              configured: true,
            },
          ],
          recoveryCodesExist: true,
        },
      },
    })

    await view.events.click(view.getByRole('button', { name: 'Regenerate recovery codes' }))

    const flyout = await view.findByRole('complementary', {
      name: 'Generate recovery codes: Confirm password',
    })

    const flyoutContent = within(flyout)

    const passwordInput = flyoutContent.getByLabelText('Current password')

    mockUserCurrentPasswordCheckMutation({
      userCurrentPasswordCheck: {
        success: true,
      },
    })

    mockUserCurrentTwoFactorRecoveryCodesGenerateMutation({
      userCurrentTwoFactorRecoveryCodesGenerate: {
        recoveryCodes,
      },
    })

    await view.events.type(passwordInput, 'test')
    await view.events.click(view.getByRole('button', { name: 'Next' }))

    await waitForUserCurrentPasswordCheckMutationCalls()
    await waitForUserCurrentTwoFactorRecoveryCodesGenerateMutationCalls()

    await view.events.click(view.getByRole('button', { name: 'Copy codes' }))

    expect(copyToClipboardMock).toHaveBeenCalledWith(recoveryCodes.join('\n'))
  })
})
