// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import {
  mockPublicLinks,
  mockPublicLinksSubscription,
} from '@shared/entities/public-links/__tests__/mocks/mockPublicLinks'
import { LoginDocument } from '@shared/graphql/mutations/login.api'
import { visitView } from '@tests/support/components/visitView'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'

describe('testing login error handling', () => {
  beforeEach(() => {
    mockPublicLinks([])
    mockPublicLinksSubscription()
  })

  it('check required login fields', async () => {
    const view = await visitView('/login')
    await view.events.click(view.getByText('Sign in'))
    const error = view.getAllByText('This field is required.')

    expect(error).toHaveLength(2)
  })

  it('check that login request error is visible', async () => {
    mockGraphQLApi(LoginDocument).willFailWithUserError({
      login: {
        sessionId: null,
        errors: [
          {
            message:
              'Login failed. Have you double-checked your credentials and completed the email verification step?',
          },
        ],
      },
    })

    const view = await visitView('/login')

    const loginInput = view.getByPlaceholderText('Username / Email')
    const passwordInput = view.getByPlaceholderText('Password')

    await view.events.type(loginInput, 'admin@example.com')
    await view.events.type(passwordInput, 'wrong')

    await view.events.click(view.getByText('Sign in'))

    expect(view.getByTestId('notification')).toBeInTheDocument()
    expect(view.getByTestId('notification')).toHaveTextContent(
      'Login failed. Have you double-checked your credentials and completed the email verification step?',
    )
  })
})
