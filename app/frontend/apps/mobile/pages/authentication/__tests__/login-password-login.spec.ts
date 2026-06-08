// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import {
  mockPublicLinks,
  mockPublicLinksSubscription,
} from '#shared/entities/public-links/__tests__/mocks/mockPublicLinks.ts'
import { mockLoginMutationError } from '#shared/graphql/mutations/login.mocks.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

describe('password login', () => {
  beforeEach(() => {
    mockPublicLinks([])
    mockPublicLinksSubscription()
  })

  it('shows if the setting is turned on', async () => {
    const applicationConfig = {
      user_show_password_login: true,
    }

    mockApplicationConfig(applicationConfig)

    const view = await visitView('/login')

    expect(view.getByText('Username / Email')).toBeInTheDocument()
    expect(view.getByText('Password')).toBeInTheDocument()
    expect(view.getByText('Sign in')).toBeInTheDocument()
  })

  it('shows if only the setting is turned off', async () => {
    const applicationConfig = {
      user_show_password_login: false,
    }

    mockApplicationConfig(applicationConfig)

    const view = await visitView('/login')

    expect(view.getByText('Username / Email')).toBeInTheDocument()
    expect(view.getByText('Password')).toBeInTheDocument()
    expect(view.getByText('Sign in')).toBeInTheDocument()
  })

  it('hides if the setting is turned off and at least one auth provider is configured', async () => {
    const applicationConfig = {
      user_show_password_login: false,
      auth_sso: true,
    }

    mockApplicationConfig(applicationConfig)

    const view = await visitView('/login')

    expect(view.queryByText('Username / Email')).not.toBeInTheDocument()
    expect(view.queryByText('Password')).not.toBeInTheDocument()
    expect(view.queryByText('Sign in')).not.toBeInTheDocument()

    expect(
      view.getByText(
        'If you have problems with the third-party login you can request a one-time password login as an admin.',
      ),
    ).toBeInTheDocument()

    const link = view.getByText('Request the password login here.')

    expect(link).toHaveAttribute('href', '/#admin_password_auth')
    expect(link).not.toHaveAttribute('target', '_blank')
  })

  it('clears and focuses password field on errors', async () => {
    mockApplicationConfig({
      user_show_password_login: true,
    })

    const view = await visitView('/login')

    const username = view.getByLabelText('Username / Email')

    await view.events.type(username, 'admin@example.com')

    const password = view.getByLabelText('Password')

    await view.events.type(password, 'wrong-password')

    // Sanity check.
    expect(username).toHaveValue('admin@example.com')
    expect(password).toHaveValue('wrong-password')

    mockLoginMutationError(
      'Login failed. Have you double-checked your credentials and completed the email verification step?',
      {
        type: GraphQLErrorTypes.NotAuthorized,
      },
    )

    await view.events.click(view.getByRole('button', { name: 'Sign in' }))

    await waitFor(() => {
      expect(username).toHaveValue('admin@example.com')
      expect(password).toHaveValue('')
      expect(password).toHaveFocus()
    })
  })
})
