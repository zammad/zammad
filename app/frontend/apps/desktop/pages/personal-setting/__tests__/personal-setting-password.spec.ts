// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { ExtendedRenderResult } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { mockUserCurrentChangePasswordMutation } from '../graphql/mutations/userCurrentChangePassword.mocks.ts'

const changePassword = async (
  view: ExtendedRenderResult,
  currentPassword: string,
  newPassword: string,
  newPasswordConfirm?: string,
) => {
  await view.events.type(
    await view.findByLabelText('Current password'),
    currentPassword,
  )
  await view.events.type(
    await view.findByLabelText('New password'),
    newPassword,
  )
  await view.events.type(
    await view.findByLabelText('Confirm new password'),
    newPasswordConfirm || newPassword,
  )
  await view.events.click(view.getByRole('button', { name: 'Change Password' }))
}

describe('password personal settings', () => {
  beforeEach(() => {
    mockUserCurrent({
      firstname: 'John',
      lastname: 'Doe',
    })

    mockPermissions(['user_preferences.password'])

    mockApplicationConfig({
      user_show_password_login: true,
    })
  })

  it('redirects to the error page when password login is disabled', async () => {
    mockApplicationConfig({
      user_show_password_login: false,
    })

    const view = await visitView('/personal-setting/password')

    await vi.waitFor(() => {
      expect(view, 'correctly redirects to error page').toHaveCurrentUrl(
        '/error-tab',
      )
    })
  })

  it('shows the form to change the password', async () => {
    const view = await visitView('/personal-setting/password')

    expect(view.getByText('Current password')).toBeInTheDocument()
    expect(view.getByText('New password')).toBeInTheDocument()
    expect(view.getByText('Confirm new password')).toBeInTheDocument()

    expect(
      view.getByRole('button', { name: 'Change Password' }),
    ).toBeInTheDocument()
  })

  it('shows an error message when e.g. current password is incorrect', async () => {
    mockUserCurrentChangePasswordMutation({
      userCurrentChangePassword: {
        success: false,
        errors: [
          {
            message: 'The current password you provided is incorrect.',
            field: 'current_password',
          },
        ],
      },
    })

    const view = await visitView('/personal-setting/password')

    await changePassword(view, 'wrong-password', 'new-password')

    expect(
      await view.findByText('The current password you provided is incorrect.'),
    ).toBeInTheDocument()
  })

  it('shows an error message when new password and confirmation do not match', async () => {
    const view = await visitView('/personal-setting/password')

    await changePassword(view, 'old-password', 'new-password', 'wrong-password')

    expect(
      await view.findByText(
        "This field doesn't correspond to the expected value.",
      ),
    ).toBeInTheDocument()
  })

  it('shows a success message when password was changed successfully', async () => {
    mockUserCurrentChangePasswordMutation({
      userCurrentChangePassword: {
        success: true,
        errors: null,
      },
    })

    const view = await visitView('/personal-setting/password')

    await changePassword(view, 'old-password', 'new-password')

    expect(
      await view.findByText('Password changed successfully.'),
    ).toBeInTheDocument()
  })
})
