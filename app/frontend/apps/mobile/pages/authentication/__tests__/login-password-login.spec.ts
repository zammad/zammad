// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import {
  mockPublicLinks,
  mockPublicLinksSubscription,
} from '#shared/entities/public-links/__tests__/mocks/mockPublicLinks.ts'

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
})
