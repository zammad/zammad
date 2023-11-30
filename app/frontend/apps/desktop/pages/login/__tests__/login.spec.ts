// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { waitForGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
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

    // graphql will automatically generate result based on the query, so we don't need to mock it preemptively
    await view.events.click(view.getByRole('button', { name: 'Sign in' }))

    // we wait until the query is resolved and then assert how it was called
    // this is usually not needed if there is e2e test covering both frontend and backend
    // but this can also be used to wait until the query is resolved
    // we could also have used "mockGraphQLResult" before pressing the button and passed down the partial result, and automocker would generate the rest
    const graphqlResult = await waitForGraphQLMockCalls('mutation', 'login')

    expect(graphqlResult).toHaveLength(1)
    // you can use graphqlResult.at(-1) to get the last call if there are several calls
    expect(graphqlResult[0].variables).toEqual({
      input: {
        login: 'admin@example.com',
        password: 'test',
        rememberMe: false,
      },
    })

    // we can't really wait for it via usual methods, so we just check this ever few ms
    await vi.waitFor(() => {
      // we can check current url with the new custom assertion "toHaveCurrentUrl"
      expect(view, 'correctly redirects to home').toHaveCurrentUrl('/')
    })
  })
})
