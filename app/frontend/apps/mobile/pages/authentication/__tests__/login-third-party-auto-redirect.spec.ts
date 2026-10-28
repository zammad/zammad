// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import {
  mockPublicLinks,
  mockPublicLinksSubscription,
} from '#shared/entities/public-links/__tests__/mocks/mockPublicLinks.ts'

const submittedActions = () =>
  vi
    .mocked(HTMLFormElement.prototype.submit)
    .mock.contexts.map((form) => (form as HTMLFormElement).getAttribute('action'))

describe('automatic redirect to the third-party login', () => {
  beforeEach(() => {
    localStorage.clear()
    sessionStorage.clear()

    mockPublicLinks([])
    mockPublicLinksSubscription()

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

  it('shows the login page after a logout and resumes when a provider is clicked', async () => {
    localStorage.setItem('third-party-login-auto-redirect-paused', 'true')

    const view = await visitView('/login')

    expect(submittedActions()).toEqual([])

    await view.events.click(view.getByRole('button', { name: 'SAML' }))

    expect(localStorage.getItem('third-party-login-auto-redirect-paused')).toBeNull()
  })
})
