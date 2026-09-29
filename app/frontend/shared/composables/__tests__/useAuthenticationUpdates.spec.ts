// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockAuthentication } from '#tests/support/mock-authentication.ts'
import { mockGraphQLApi } from '#tests/support/mock-graphql-api.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick, waitUntil } from '#tests/support/utils.ts'

import { LogoutDocument } from '#shared/graphql/mutations/logout.api.ts'
import { mockSessionQuery } from '#shared/graphql/queries/session.mocks.ts'
import {
  authenticationInvalidated,
  setAuthenticationInvalidated,
} from '#shared/server/apollo/utils/authenticationState.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import useAuthenticationChanges from '../authentication/useAuthenticationUpdates.ts'

vi.mock('#shared/server/apollo/client.ts', () => {
  return {
    clearApolloClientStore: () => {
      return Promise.resolve()
    },
  }
})

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

  describe('maintenance mode', () => {
    const mockLogout = () =>
      mockGraphQLApi(LogoutDocument).willResolve({
        logout: {
          success: true,
          errors: null,
          externalLogoutUrl: null,
        },
      })

    it('logs a non-admin user out when import mode turns on', async () => {
      mockApplicationConfig({ maintenance_mode: false, import_mode: false })
      mockAuthentication(true)
      mockPermissions(['ticket.agent'])
      mockLogout()

      renderAuthenticationChanges()

      useApplicationStore().config.import_mode = true

      await waitUntil(() => !useAuthenticationStore().authenticated)

      expect(useAuthenticationStore().authenticated).toBe(false)
    })

    it('keeps an admin user logged in when import mode turns on', async () => {
      mockApplicationConfig({ maintenance_mode: false, import_mode: false })
      mockAuthentication(true)
      mockPermissions(['admin.maintenance'])

      const logout = vi.spyOn(useAuthenticationStore(), 'logout')

      renderAuthenticationChanges()

      useApplicationStore().config.import_mode = true
      await waitForNextTick(true)

      expect(logout).not.toHaveBeenCalled()
      expect(useAuthenticationStore().authenticated).toBe(true)
    })

    it('does not log out again when maintenance mode toggles while import mode stays on', async () => {
      mockApplicationConfig({ maintenance_mode: true, import_mode: true })
      mockAuthentication(true)
      mockPermissions(['ticket.agent'])

      const logout = vi.spyOn(useAuthenticationStore(), 'logout')

      renderAuthenticationChanges()

      const application = useApplicationStore()

      application.config.maintenance_mode = false
      await waitForNextTick(true)
      application.config.maintenance_mode = true
      await waitForNextTick(true)

      expect(logout).not.toHaveBeenCalled()
      expect(useAuthenticationStore().authenticated).toBe(true)
    })
  })
})
