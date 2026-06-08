// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { createMockCredential, mockWebAuthnCreation } from '#tests/support/mock-webauthn.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import {
  mockUserCurrentTwoFactorGetMethodConfigurationQuery,
  waitForUserCurrentTwoFactorGetMethodConfigurationQueryCalls,
} from '#shared/entities/user/current/graphql/mutations/two-factor/userCurrentTwoFactorGetMethodConfiguration.mocks.ts'
import {
  mockUserCurrentTwoFactorRemoveMethodCredentialsMutation,
  waitForUserCurrentTwoFactorRemoveMethodCredentialsMutationCalls,
} from '#shared/entities/user/current/graphql/mutations/two-factor/userCurrentTwoFactorRemoveMethodCredentials.mocks.ts'
import { mockUserCurrentTwoFactorVerifyMethodConfigurationMutation } from '#shared/entities/user/current/graphql/mutations/two-factor/userCurrentTwoFactorVerifyMethodConfiguration.mocks.ts'
import { mockUserCurrentTwoFactorInitiateMethodConfigurationQuery } from '#shared/entities/user/current/graphql/queries/two-factor/userCurrentTwoFactorInitiateMethodConfiguration.mocks.ts'
import { EnumTwoFactorAuthenticationMethod } from '#shared/graphql/types.ts'

import {
  mockUserCurrentPasswordCheckMutation,
  waitForUserCurrentPasswordCheckMutationCalls,
} from '#desktop/entities/user/current/graphql/mutations/userCurrentPasswordCheck.mocks.ts'
import { getUserCurrentTwoFactorUpdatesSubscriptionHandler } from '#desktop/entities/user/current/graphql/subscriptions/userCurrentTwoFactorUpdates.mocks.ts'

describe('Two-factor Authentication - Security Keys', () => {
  beforeEach(() => {
    mockApplicationConfig({
      two_factor_authentication_method_security_keys: true,
    })
  })

  it('supports setting up new security keys', async () => {
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

    await waitFor(() =>
      expect(flyout).toHaveAccessibleName('Set up two-factor authentication: Security keys'),
    )

    expect(flyout).toHaveTextContent(
      'Security keys are hardware or software credentials that can be used as your two-factor authentication method.To register a new security key with your account, press the button below.',
    )

    await view.events.click(view.getByRole('button', { name: 'Set up' }))

    const nicknameInput = flyoutContent.getByLabelText('Name for this security key')

    await view.events.type(nicknameInput, 'My key')

    await view.events.click(view.getByRole('button', { name: 'Next' }))

    await waitFor(() =>
      expect(flyout).toHaveAccessibleName('Set up two-factor authentication: Save codes'),
    )
  })

  it('supports removal of existing security keys', async () => {
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

    const actionMenuButton = view.getByRole('button', {
      name: 'Action menu button for security keys',
    })

    await view.events.click(actionMenuButton)

    const actionMenuItem = view.getByRole('button', { name: 'Edit' })

    await view.events.click(actionMenuItem)

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
      userCurrentTwoFactorGetMethodConfiguration: {
        credentials: [
          {
            nickname: 'foobar',
            public_key: 'foobar',
            created_at: '2024-01-01T00:00:00Z',
          },
        ],
      },
    })

    await view.events.type(passwordInput, 'test')
    await view.events.click(view.getByRole('button', { name: 'Next' }))

    await waitForUserCurrentPasswordCheckMutationCalls()
    await waitForUserCurrentTwoFactorGetMethodConfigurationQueryCalls()

    expect(flyout).toHaveTextContent('foobar')
    expect(within(flyout).getByLabelText('2024-01-01 00:00')).toBeInTheDocument()

    mockUserCurrentTwoFactorRemoveMethodCredentialsMutation({
      userCurrentTwoFactorRemoveMethodCredentials: {
        success: true,
      },
    })

    mockUserCurrentTwoFactorGetMethodConfigurationQuery({
      userCurrentTwoFactorGetMethodConfiguration: null,
    })

    await view.events.click(view.getByRole('button', { name: 'Remove' }))

    await waitForUserCurrentTwoFactorRemoveMethodCredentialsMutationCalls()
    await waitForUserCurrentTwoFactorGetMethodConfigurationQueryCalls()

    expect(flyout).not.toHaveTextContent('foobar')
    expect(flyout).not.toHaveTextContent('just now')
  })

  it('supports submitting of nickname via keyboard', async () => {
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

    await view.events.type(passwordInput, 'test')
    await view.events.click(view.getByRole('button', { name: 'Next' }))

    await waitForUserCurrentPasswordCheckMutationCalls()
    await waitForUserCurrentTwoFactorGetMethodConfigurationQueryCalls()

    await view.events.click(view.getByRole('button', { name: 'Set up' }))

    const nicknameInput = flyoutContent.getByLabelText('Name for this security key')

    mockWebAuthnCreation()

    await view.events.type(nicknameInput, 'My key{Enter}')

    await waitFor(() =>
      expect(flyout).toHaveAccessibleName('Set up two-factor authentication: Save codes'),
    )
  })

  it('shows client validation errors', async () => {
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

    await view.events.type(passwordInput, 'test')
    await view.events.click(view.getByRole('button', { name: 'Next' }))

    await waitForUserCurrentPasswordCheckMutationCalls()
    await waitForUserCurrentTwoFactorGetMethodConfigurationQueryCalls()

    await view.events.click(view.getByRole('button', { name: 'Set up' }))

    const nicknameInput = flyoutContent.getByLabelText('Name for this security key')

    await view.events.click(view.getByRole('button', { name: 'Next' }))

    expect(nicknameInput).toBeDescribedBy('This field is required.')
  })

  it('shows errors during setup phase and supports retrying', async () => {
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

    await view.events.type(passwordInput, 'test')
    await view.events.click(view.getByRole('button', { name: 'Next' }))

    await waitForUserCurrentPasswordCheckMutationCalls()
    await waitForUserCurrentTwoFactorGetMethodConfigurationQueryCalls()

    await view.events.click(view.getByRole('button', { name: 'Set up' }))

    const nicknameInput = flyoutContent.getByLabelText('Name for this security key')

    await view.events.type(nicknameInput, 'My key')

    const mocks = mockWebAuthnCreation()
    mocks.createSpy.mockRejectedValue(new Error('WebAuthn failed'))

    mockUserCurrentTwoFactorInitiateMethodConfigurationQuery({
      userCurrentTwoFactorInitiateMethodConfiguration: 'mock-error',
    })

    await view.events.click(view.getByRole('button', { name: 'Next' }))

    await waitFor(() =>
      expect(flyoutContent.getByRole('alert')).toHaveTextContent('Security key setup failed.'),
    )

    mockUserCurrentTwoFactorInitiateMethodConfigurationQuery({
      userCurrentTwoFactorInitiateMethodConfiguration: {},
    })

    mocks.createSpy.mockResolvedValue(createMockCredential())

    await view.events.click(view.getByRole('button', { name: 'Retry' }))

    waitFor(() =>
      expect(flyout).toHaveAccessibleName('Set up two-factor authentication: Save codes'),
    )
  })

  it('shows errors during verification phase', async () => {
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

    await view.events.type(passwordInput, 'test')
    await view.events.click(view.getByRole('button', { name: 'Next' }))

    mockWebAuthnCreation()

    await waitForUserCurrentPasswordCheckMutationCalls()
    await waitForUserCurrentTwoFactorGetMethodConfigurationQueryCalls()

    await view.events.click(view.getByRole('button', { name: 'Set up' }))

    const nicknameInput = flyoutContent.getByLabelText('Name for this security key')

    await view.events.type(nicknameInput, 'My key')

    mockUserCurrentTwoFactorVerifyMethodConfigurationMutation({
      userCurrentTwoFactorVerifyMethodConfiguration: {
        errors: [
          {
            message:
              'The verification of the two-factor authentication method configuration failed.',
          },
        ],
      },
    })

    await view.events.click(view.getByRole('button', { name: 'Next' }))

    expect(flyoutContent.getByRole('alert')).toHaveTextContent(
      'The verification of the two-factor authentication method configuration failed.',
    )

    mockUserCurrentTwoFactorVerifyMethodConfigurationMutation({
      userCurrentTwoFactorVerifyMethodConfiguration: {
        recoveryCodes: [],
      },
    })

    await view.events.click(view.getByRole('button', { name: 'Retry' }))

    await waitFor(() =>
      expect(flyout).toHaveAccessibleName('Set up two-factor authentication: Save codes'),
    )
  })

  it('skips recovery codes if already setup', async () => {
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

    await view.events.type(passwordInput, 'test')
    await view.events.click(view.getByRole('button', { name: 'Next' }))

    await waitForUserCurrentPasswordCheckMutationCalls()
    await waitForUserCurrentTwoFactorGetMethodConfigurationQueryCalls()

    await view.events.click(view.getByRole('button', { name: 'Set up' }))

    const nicknameInput = flyoutContent.getByLabelText('Name for this security key')

    await view.events.type(nicknameInput, 'My key')

    mockWebAuthnCreation()

    mockUserCurrentTwoFactorVerifyMethodConfigurationMutation({
      userCurrentTwoFactorVerifyMethodConfiguration: {
        recoveryCodes: null,
      },
    })

    await view.events.click(view.getByRole('button', { name: 'Next' }))

    await waitFor(() => expect(flyout).not.toBeInTheDocument())

    expect(
      view.getByText('Two-factor authentication method was set up successfully.'),
    ).toBeInTheDocument()
  })
})
