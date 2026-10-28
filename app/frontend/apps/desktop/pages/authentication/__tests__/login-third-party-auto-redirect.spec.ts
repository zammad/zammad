// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mockGraphQLResult } from '#tests/graphql/builders/mocks.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import type { AdminPasswordAuthVerifyMutation } from '#shared/graphql/types.ts'

import { AdminPasswordAuthVerifyDocument } from '../graphql/mutations/adminPasswordAuthVerify.api.ts'

const submittedActions = () =>
  vi
    .mocked(HTMLFormElement.prototype.submit)
    .mock.contexts.map((form) => (form as HTMLFormElement).getAttribute('action'))

describe('automatic redirect to the third-party login', () => {
  beforeEach(() => {
    localStorage.clear()
    sessionStorage.clear()

    vi.spyOn(HTMLFormElement.prototype, 'submit').mockImplementation(() => {})

    mockApplicationConfig({
      third_party_login_auto_redirect: true,
      user_show_password_login: false,
      auth_saml: true,
    })
  })

  it('submits the sign-in of the single provider with the requested route', async () => {
    const view = await visitView('/login?redirect=/tickets/42')

    expect(submittedActions()).toEqual([
      expect.stringMatching(/^\/auth\/saml\?fingerprint=.+&redirect=%2Ftickets%2F42$/),
    ])
    expect(view.queryByText('Sign in using')).not.toBeInTheDocument()
  })

  it('shows the login page after a logout', async () => {
    localStorage.setItem('third-party-login-auto-redirect-paused', 'true')

    const view = await visitView('/login')

    expect(submittedActions()).toEqual([])
    expect(view.getByText('Sign in using')).toBeInTheDocument()
  })

  it('shows the login page right after a redirect', async () => {
    sessionStorage.setItem('third-party-login-auto-redirect-at', String(Date.now()))

    const view = await visitView('/login')

    expect(submittedActions()).toEqual([])
    expect(view.getByText('Sign in using')).toBeInTheDocument()
  })

  it('shows the login page if more than one provider is enabled', async () => {
    mockApplicationConfig({
      third_party_login_auto_redirect: true,
      user_show_password_login: false,
      auth_saml: true,
      auth_github: true,
    })

    await visitView('/login')

    expect(submittedActions()).toEqual([])
  })

  it('shows the login page if password login is enabled', async () => {
    mockApplicationConfig({
      third_party_login_auto_redirect: true,
      user_show_password_login: true,
      auth_saml: true,
    })

    await visitView('/login')

    expect(submittedActions()).toEqual([])
  })

  it('shows the login page if the setting is disabled', async () => {
    mockApplicationConfig({
      user_show_password_login: false,
      auth_saml: true,
    })

    await visitView('/login')

    expect(submittedActions()).toEqual([])
  })

  it('shows the login page in maintenance mode', async () => {
    mockApplicationConfig({
      third_party_login_auto_redirect: true,
      user_show_password_login: false,
      auth_saml: true,
      maintenance_mode: true,
    })

    await visitView('/login')

    expect(submittedActions()).toEqual([])
  })

  it('shows the password login for the admin password login link', async () => {
    mockGraphQLResult<AdminPasswordAuthVerifyMutation>(AdminPasswordAuthVerifyDocument, {
      adminPasswordAuthVerify: { login: 'admin@example.com' },
    })

    const view = await visitView('/login?token=valid-token')

    expect(submittedActions()).toEqual([])
    expect(await view.findByLabelText('Username / Email')).toBeInTheDocument()
  })

  it('resumes the automatic redirect when a provider is clicked', async () => {
    localStorage.setItem('third-party-login-auto-redirect-paused', 'true')

    const view = await visitView('/login')

    await view.events.click(view.getByRole('button', { name: 'SAML' }))

    expect(localStorage.getItem('third-party-login-auto-redirect-paused')).toBeNull()
  })
})
