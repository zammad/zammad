// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { waitUntil } from '#tests/support/utils.ts'

import { mockSessionQuery } from '#shared/graphql/queries/session.mocks.ts'
import {
  authenticationInvalidated,
  setAuthenticationInvalidated,
} from '#shared/server/apollo/utils/authenticationState.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import useAuthenticationChanges from '../authentication/useAuthenticationUpdates.ts'

const renderAuthenticationChanges = () =>
  renderComponent(
    {
      template: '<div></div>',
      setup() {
        useAuthenticationChanges()
      },
    },
    {
      router: true,
      store: true,
    },
  )

describe('useAuthenticationUpdates', () => {
  afterEach(() => {
    // Make sure no state of a previous example is left behind.
    setAuthenticationInvalidated(false)
  })

  it('resets the authentication invalidation when another tab restored the session', async () => {
    mockSessionQuery({
      session: {
        id: 'restored-session-id',
        afterAuth: null,
      },
    })

    renderAuthenticationChanges()

    const authentication = useAuthenticationStore()
    const session = useSessionStore()

    session.id = 'current-session-id'
    authentication.authenticated = true

    // This tab logs out, which tells the Apollo layer to expect authentication
    //  errors from the operations which are still on their way out.
    await authentication.clearAuthentication()

    expect(authenticationInvalidated()).toBe(true)

    // Another tab logs in, which syncs the authenticated flag back through the
    //  local storage, so that this tab restores its session.
    authentication.authenticated = true

    await waitUntil(() => session.user)

    expect(session.id).toBe('restored-session-id')

    // Without the reset, the Apollo layer would keep silencing the
    //  authentication errors of the restored session, so that an expiring
    //  session would leave the tab behind in the authenticated interface.
    expect(authenticationInvalidated()).toBe(false)
  })
})
