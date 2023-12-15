// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { LoginDocument } from '#shared/graphql/mutations/login.api.ts'
import type { LoginMutation } from '#shared/graphql/types.ts'
import {
  mockGraphQLResult,
  waitForGraphQLMockCalls,
} from '#tests/graphql/builders/mocks.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

describe('logging in', () => {
  mockApplicationConfig({})

  it('can login using login form', async () => {
    const view = await visitView('/login')

    const username = view.getByLabelText('Username / Email')
    await view.events.type(username, 'admin@example.com')

    const password = view.getByLabelText('Password')
    await view.events.type(password, 'test')

    // We mock GraphQL result before pressing the button and pass down the partial result,
    //   and automocker will generate the rest.
    mockGraphQLResult<LoginMutation>(LoginDocument, {
      login: {
        session: {
          id: '6605e8986992bf38b8a03638a5c6090e',
          afterAuth: null,
        },
        errors: null,
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
