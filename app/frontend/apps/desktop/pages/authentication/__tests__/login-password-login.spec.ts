// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { waitForGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { mockLoginMutation } from '#shared/graphql/mutations/login.mocks.ts'

describe('password login', () => {
  it('shows if the setting is turned on', async () => {
    mockApplicationConfig({
      user_show_password_login: true,
    })

    const view = await visitView('/login')

    expect(view.getByText('Username / Email')).toBeInTheDocument()
    expect(view.getByText('Password')).toBeInTheDocument()
    expect(view.getByText('Sign in')).toBeInTheDocument()
  })

  it('shows if only the setting is turned off', async () => {
    mockApplicationConfig({
      user_show_password_login: false,
    })

    const view = await visitView('/login')

    expect(view.getByText('Username / Email')).toBeInTheDocument()
    expect(view.getByText('Password')).toBeInTheDocument()
    expect(view.getByText('Sign in')).toBeInTheDocument()
  })

  it('hides if the setting is turned off and at least one auth provider is configured', async () => {
    mockApplicationConfig({
      user_show_password_login: false,
      auth_sso: true,
    })

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

    expect(link).toHaveAttribute('href', '/desktop/admin-password-auth')
    expect(link).not.toHaveAttribute('target', '_blank')
  })

  it('can login using login form', async () => {
    mockApplicationConfig({
      user_show_password_login: true,
    })

    const view = await visitView('/login')

    const username = view.getByLabelText('Username / Email')
    await view.events.type(username, 'admin@example.com')

    const password = view.getByLabelText('Password')
    await view.events.type(password, 'test')

    // We mock GraphQL result before pressing the button and pass down the partial result,
    //   and automocker will generate the rest.
    mockLoginMutation({
      login: {
        twoFactorRequired: null,
      },
    })

    await view.events.click(view.getByRole('button', { name: 'Sign in' }))

    // We wait until the query is resolved and then assert how it was called.
    //   This is usually not needed if there is an E2E test covering both frontend and backend,
    //   But this can also be used to wait until the query is resolved.
    const graphqlResult = await waitForGraphQLMockCalls('mutation', 'login')

    expect(graphqlResult).toHaveLength(1)

    // It's possible to use `graphqlResult.at(-1)` to get the last call if there are several calls expected.
    expect(graphqlResult[0].variables).toEqual({
      input: {
        login: 'admin@example.com',
        password: 'test',
        rememberMe: false,
      },
    })

    // We can't really wait for it via usual methods, so we just check it ever few ms.
    await vi.waitFor(() => {
      // We can check current url with the new custom assertion `.toHaveCurrentUrl()`.
      expect(view, 'correctly redirects to home').toHaveCurrentUrl('/')
    })
  })
})
