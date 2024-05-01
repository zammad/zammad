// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import {
  mockAccountPasswordCheckMutation,
  waitForAccountPasswordCheckMutationCalls,
} from '#desktop/entities/account/graphql/mutations/accountPasswordCheck.mocks.ts'
import { EnumTwoFactorAuthenticationMethod } from '#shared/graphql/types.ts'
import {
  mockAccountTwoFactorRecoveryCodesGenerateMutation,
  waitForAccountTwoFactorRecoveryCodesGenerateMutationCalls,
} from '#shared/entities/account/graphql/mutations/accountTwoFactorRecoveryCodesGenerate.mocks.ts'
import {
  mockAccountTwoFactorGetMethodConfigurationQuery,
  waitForAccountTwoFactorGetMethodConfigurationQueryCalls,
} from '#shared/entities/account/graphql/mutations/accountTwoFactorGetMethodConfiguration.mocks.ts'
import { mockAccountTwoFactorVerifyMethodConfigurationMutation } from '#shared/entities/account/graphql/mutations/accountTwoFactorVerifyMethodConfiguration.mocks.ts'
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

const clipboardCopyMock = vi.fn()

vi.mock('@vueuse/core', async () => {
  const mod =
    await vi.importActual<typeof import('@vueuse/core')>('@vueuse/core')

  return {
    ...mod,
    useClipboard: () => ({
      copy: clipboardCopyMock,
      copied: vi.fn(),
    }),
  }
})

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
              authenticationMethod:
                EnumTwoFactorAuthenticationMethod.SecurityKeys,
              configured: true,
            },
          ],
          recoveryCodesExist: true,
        },
      },
    })

    await view.events.click(
      view.getByRole('button', { name: 'Regenerate Recovery Codes' }),
    )

    const flyout = await view.findByRole('complementary', {
      name: 'Generate Recovery Codes: Confirm Password',
    })

    const flyoutContent = within(flyout)

    const passwordInput = flyoutContent.getByLabelText('Current password')

    mockAccountPasswordCheckMutation({
      accountPasswordCheck: {
        success: true,
      },
    })

    mockAccountTwoFactorRecoveryCodesGenerateMutation({
      accountTwoFactorRecoveryCodesGenerate: {
        recoveryCodes,
      },
    })

    await view.events.type(passwordInput, 'test')
    await view.events.click(view.getByRole('button', { name: 'Next' }))

    await waitForAccountPasswordCheckMutationCalls()
    await waitForAccountTwoFactorRecoveryCodesGenerateMutationCalls()

    expect(flyout).toHaveAccessibleName('Generate Recovery Codes: Save Codes')

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
    const view = await visitView('/personal-setting/two-factor-auth')

    const actionMenuButton = view.getByRole('button', {
      name: 'Set up security keys',
    })

    await view.events.click(actionMenuButton)

    const flyout = await view.findByRole('complementary', {
      name: 'Set Up Two-factor Authentication: Confirm Password',
    })

    const flyoutContent = within(flyout)

    const passwordInput = flyoutContent.getByLabelText('Current password')

    mockAccountPasswordCheckMutation({
      accountPasswordCheck: {
        success: true,
      },
    })

    mockAccountTwoFactorGetMethodConfigurationQuery({
      accountTwoFactorGetMethodConfiguration: null,
    })

    await view.events.type(passwordInput, 'test')
    await view.events.click(view.getByRole('button', { name: 'Next' }))

    await waitForAccountPasswordCheckMutationCalls()
    await waitForAccountTwoFactorGetMethodConfigurationQueryCalls()

    await view.events.click(view.getByRole('button', { name: 'Set Up' }))

    const nicknameInput = flyoutContent.getByLabelText(
      'Name for this security key',
    )

    await view.events.type(nicknameInput, 'My key')

    Object.defineProperty(window, 'isSecureContext', {
      value: true,
    })

    vi.mock('@github/webauthn-json', () => ({
      create: vi.fn(),
    }))

    mockAccountTwoFactorVerifyMethodConfigurationMutation({
      accountTwoFactorVerifyMethodConfiguration: {
        recoveryCodes,
      },
    })

    await view.events.click(view.getByRole('button', { name: 'Next' }))

    expect(flyout).toHaveAccessibleName(
      'Set Up Two-factor Authentication: Save Codes',
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
              authenticationMethod:
                EnumTwoFactorAuthenticationMethod.SecurityKeys,
              configured: true,
            },
          ],
          recoveryCodesExist: true,
        },
      },
    })

    await view.events.click(
      view.getByRole('button', { name: 'Regenerate Recovery Codes' }),
    )

    const flyout = await view.findByRole('complementary', {
      name: 'Generate Recovery Codes: Confirm Password',
    })

    const flyoutContent = within(flyout)

    const passwordInput = flyoutContent.getByLabelText('Current password')

    mockAccountPasswordCheckMutation({
      accountPasswordCheck: {
        success: true,
      },
    })

    mockAccountTwoFactorRecoveryCodesGenerateMutation({
      accountTwoFactorRecoveryCodesGenerate: {
        recoveryCodes,
      },
    })

    await view.events.type(passwordInput, 'test')
    await view.events.click(view.getByRole('button', { name: 'Next' }))

    await waitForAccountPasswordCheckMutationCalls()
    await waitForAccountTwoFactorRecoveryCodesGenerateMutationCalls()

    const printArea = flyoutContent.getByTestId('print-area')

    expect(printArea).toHaveClass('print-area')

    Object.defineProperty(window, 'print', {
      value: vi.fn(),
    })

    await view.events.click(view.getByRole('button', { name: 'Print Codes' }))

    expect(window.print).toHaveBeenCalledOnce()
  })

  it('supports copying generated recovery codes to clipboard', async () => {
    const view = await visitView('/personal-setting/two-factor-auth')

    await getUserCurrentTwoFactorUpdatesSubscriptionHandler().trigger({
      userCurrentTwoFactorUpdates: {
        configuration: {
          enabledAuthenticationMethods: [
            {
              authenticationMethod:
                EnumTwoFactorAuthenticationMethod.SecurityKeys,
              configured: true,
            },
          ],
          recoveryCodesExist: true,
        },
      },
    })

    await view.events.click(
      view.getByRole('button', { name: 'Regenerate Recovery Codes' }),
    )

    const flyout = await view.findByRole('complementary', {
      name: 'Generate Recovery Codes: Confirm Password',
    })

    const flyoutContent = within(flyout)

    const passwordInput = flyoutContent.getByLabelText('Current password')

    mockAccountPasswordCheckMutation({
      accountPasswordCheck: {
        success: true,
      },
    })

    mockAccountTwoFactorRecoveryCodesGenerateMutation({
      accountTwoFactorRecoveryCodesGenerate: {
        recoveryCodes,
      },
    })

    await view.events.type(passwordInput, 'test')
    await view.events.click(view.getByRole('button', { name: 'Next' }))

    await waitForAccountPasswordCheckMutationCalls()
    await waitForAccountTwoFactorRecoveryCodesGenerateMutationCalls()

    await view.events.click(view.getByRole('button', { name: 'Copy Codes' }))

    expect(clipboardCopyMock).toHaveBeenCalledWith(recoveryCodes.join('\n'))
  })
})
