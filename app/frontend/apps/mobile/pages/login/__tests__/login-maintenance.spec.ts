// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { useApplicationStore } from '@shared/stores/application'
import { visitView } from '@tests/support/components/visitView'
import { mockApplicationConfig } from '@tests/support/mock-applicationConfig'
import { mockAuthentication } from '@tests/support/mock-authentication'
import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '@tests/support/mock-graphql-api'
import { ConfigUpdatesDocument } from '@shared/graphql/subscriptions/configUpdates.api'
import { LogoutDocument } from '@shared/graphql/mutations/logout.api'
import { ApplicationConfigDocument } from '@shared/graphql/queries/applicationConfig.api'
import { waitFor } from '@testing-library/vue'
import { useAuthenticationStore } from '@shared/stores/authentication'
import { mockPermissions } from '@tests/support/mock-permissions'
import {
  mockPublicLinks,
  mockPublicLinksSubscription,
} from '@shared/entities/public-links/__tests__/mocks/mockPublicLinks'

vi.mock('@shared/server/apollo/client', () => {
  return {
    clearApolloClientStore: () => {
      return Promise.resolve()
    },
  }
})

beforeEach(() => {
  mockPublicLinks([])
  mockPublicLinksSubscription()
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

  it('check for maintenance mode message', async () => {
    mockApplicationConfig({
      maintenance_mode: true,
    })

    const view = await visitView('/login')

    const maintenanceModeMessage = view.queryByText(
      'Zammad is currently in maintenance mode. Only administrators can log in. Please wait until the maintenance window is over.',
    )

    expect(maintenanceModeMessage).toBeInTheDocument()
  })

  it('check for maintenance mode login custom message (e.g. to announce maintenance)', async () => {
    mockApplicationConfig({
      maintenance_login: true,
      maintenance_login_message: 'Custom maintenance login message.',
    })

    const view = await visitView('/login')

    const maintenanceModeCustomMessage = view.queryByText(
      'Custom maintenance login message.',
    )

    expect(maintenanceModeCustomMessage).toBeInTheDocument()
  })

  it('does not logout for admin user after maintenance mode switch', async () => {
    mockApplicationConfig({
      maintenance_mode: false,
    })
    mockAuthentication(true)
    mockPermissions(['admin.maintenance'])

    const mockSubscription = mockGraphQLSubscription(ConfigUpdatesDocument)

    const application = useApplicationStore()
    application.initializeConfigUpdateSubscription()

    await visitView('/')

    // Change maintenance mode to trigger the logout for non admin user.
    await mockSubscription.next({
      data: {
        configUpdates: {
          setting: {
            key: 'maintenance_mode',
            value: true,
          },
        },
      },
    })

    expect(useAuthenticationStore().authenticated).toBe(true)
  })

  it('check logout for non admin user after maintenance mode switch', async () => {
    mockApplicationConfig({
      maintenance_mode: false,
    })
    mockAuthentication(true)
    mockPermissions(['agent'])

    mockGraphQLApi(LogoutDocument).willResolve({
      logout: {
        success: true,
        errors: null,
      },
    })

    const mockSubscription = mockGraphQLSubscription(ConfigUpdatesDocument)

    const application = useApplicationStore()
    application.initializeConfigUpdateSubscription()

    mockGraphQLApi(ApplicationConfigDocument).willResolve({
      applicationConfig: [
        {
          key: 'maintenance_mode',
          value: true,
        },
      ],
    })

    const view = await visitView('/')

    // Change maintenance mode to trigger the logout for non admin user.
    await mockSubscription.next({
      data: {
        configUpdates: {
          setting: {
            key: 'maintenance_mode',
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
  })
})
