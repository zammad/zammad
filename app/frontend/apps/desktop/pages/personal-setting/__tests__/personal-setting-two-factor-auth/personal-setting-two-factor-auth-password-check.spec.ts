// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import {
  mockUserCurrentTwoFactorGetMethodConfigurationQuery,
  waitForUserCurrentTwoFactorGetMethodConfigurationQueryCalls,
} from '#shared/entities/user/current/graphql/mutations/two-factor/userCurrentTwoFactorGetMethodConfiguration.mocks.ts'

import {
  mockUserCurrentPasswordCheckMutation,
  waitForUserCurrentPasswordCheckMutationCalls,
} from '#desktop/entities/user/current/graphql/mutations/userCurrentPasswordCheck.mocks.ts'

describe('Two-factor Authentication - Password Check', () => {
  beforeEach(() => {
    mockApplicationConfig({
      two_factor_authentication_method_security_keys: true,
    })
  })

  it('checks the password before allowing to proceed', async () => {
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

    expect(passwordInput).not.toBeInTheDocument()

    expect(flyout).toHaveAccessibleName(
      'Set Up Two-factor Authentication: Security Keys',
    )
  })

  it('supports submitting form via keyboard', async () => {
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

    mockUserCurrentPasswordCheckMutation({
      userCurrentPasswordCheck: {
        success: true,
      },
    })

    await view.events.type(passwordInput, 'test{Enter}')

    await waitForUserCurrentPasswordCheckMutationCalls()

    expect(passwordInput).not.toBeInTheDocument()
  })

  it('shows client validation errors', async () => {
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

    await view.events.type(passwordInput, '{Enter}')

    expect(passwordInput).toBeDescribedBy('This field is required.')
  })

  it('shows server-side validation errors', async () => {
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

    mockUserCurrentPasswordCheckMutation({
      userCurrentPasswordCheck: {
        success: false,
        errors: [
          {
            field: 'password',
            message: 'The provided password is incorrect.',
          },
        ],
      },
    })

    await view.events.type(passwordInput, 'test')
    await view.events.click(view.getByRole('button', { name: 'Next' }))

    expect(passwordInput).toBeDescribedBy('The provided password is incorrect.')
  })
})
