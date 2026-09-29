// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockAuthentication } from '#tests/support/mock-authentication.ts'
import { mockGraphQLApi, mockGraphQLSubscription } from '#tests/support/mock-graphql-api.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockTicketOverviews } from '#tests/support/mocks/ticket-overviews.ts'

import {
  mockPublicLinks,
  mockPublicLinksSubscription,
} from '#shared/entities/public-links/__tests__/mocks/mockPublicLinks.ts'
import { LogoutDocument } from '#shared/graphql/mutations/logout.api.ts'
import { ApplicationConfigDocument } from '#shared/graphql/queries/applicationConfig.api.ts'
import { ConfigUpdatesDocument } from '#shared/graphql/subscriptions/configUpdates.api.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'

vi.mock('#shared/server/apollo/client.ts', () => {
  return {
    clearApolloClientStore: () => {
      return Promise.resolve()
    },
  }
})

beforeEach(() => {
  mockTicketOverviews()
  mockPublicLinks([])
  mockPublicLinksSubscription()
  mockApplicationConfig({ product_name: 'Zammad' })
})

describe('testing login maintenance mode', () => {
  it('check not visible maintenance mode message, when maintenance mode is not active', async () => {
    mockApplicationConfig({
      maintenance_mode: false,
    })

    const view = await visitView('/login')

    const maintenanceModeMessage = view.queryByText(
      'Zammad is currently in maintenance mode. Only administrators can log in. Please wait until the maintenance window is over.',
    )

    expect(maintenanceModeMessage).not.toBeInTheDocument()
  })

  it.each(['maintenance_mode', 'import_mode'])(
    'check for maintenance mode message when %s is active',
    async (setting) => {
      mockApplicationConfig({
        [setting]: true,
      })

      const view = await visitView('/login')

      const maintenanceModeMessage = view.queryByText(
        'Zammad is currently in maintenance mode. Only administrators can log in. Please wait until the maintenance window is over.',
      )

      expect(maintenanceModeMessage).toBeInTheDocument()
    },
  )

  it('check for maintenance mode login custom message (e.g. to announce maintenance)', async () => {
    mockApplicationConfig({
      maintenance_login: true,
      maintenance_login_message: 'Custom maintenance login message.',
    })

    const view = await visitView('/login')

    const maintenanceModeCustomMessage = view.queryByText('Custom maintenance login message.')

    expect(maintenanceModeCustomMessage).toBeInTheDocument()
  })

  it.each(['maintenance_mode', 'import_mode'])(
    'does not logout for admin user after %s switch',
    async (setting) => {
      mockApplicationConfig({
        maintenance_mode: false,
        import_mode: false,
      })
      mockAuthentication(true)
      mockPermissions(['admin.maintenance'])

      const mockSubscription = mockGraphQLSubscription(ConfigUpdatesDocument)

      const application = useApplicationStore()
      application.initializeConfigUpdateSubscription()

      await visitView('/')

      await mockSubscription.next({
        data: {
          configUpdates: {
            setting: {
              key: setting,
              value: true,
            },
          },
        },
      })

      expect(useAuthenticationStore().authenticated).toBe(true)
    },
  )

  it.each(['maintenance_mode', 'import_mode'])(
    'check logout for non admin user after %s switch',
    async (setting) => {
      mockApplicationConfig({
        maintenance_mode: false,
        import_mode: false,
      })
      mockAuthentication(true)
      mockPermissions(['ticket.agent'])

      mockGraphQLApi(LogoutDocument).willResolve({
        logout: {
          success: true,
          errors: null,
          externalLogoutUrl: null,
        },
      })

      const mockSubscription = mockGraphQLSubscription(ConfigUpdatesDocument)

      const application = useApplicationStore()
      application.initializeConfigUpdateSubscription()

      mockGraphQLApi(ApplicationConfigDocument).willResolve({
        applicationConfig: [
          {
            key: setting,
            value: true,
          },
          {
            key: 'product_name',
            value: 'Zammad',
          },
        ],
      })

      const view = await visitView('/')

      await mockSubscription.next({
        data: {
          configUpdates: {
            setting: {
              key: setting,
              value: true,
            },
          },
        },
      })

      expect(useAuthenticationStore().authenticated).toBe(false)

      await waitFor(() => {
        const maintenanceModeMessage = view.queryByText(
          'Zammad is currently in maintenance mode. Only administrators can log in. Please wait until the maintenance window is over.',
        )

        expect(maintenanceModeMessage).toBeInTheDocument()
      })
    },
  )
})
