// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import {
  type ExtendedIMockSubscription,
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '#tests/support/mock-graphql-api.ts'

import { useNotifications } from '#shared/components/CommonNotifications/index.ts'
import { ApplicationBuildChecksumDocument } from '#shared/graphql/queries/applicationBuildChecksum.api.ts'
import { AppMaintenanceDocument } from '#shared/graphql/subscriptions/appMaintenance.api.ts'
import { EnumAppMaintenanceType } from '#shared/graphql/types.ts'

import useAppMaintenanceCheck from '../useAppMaintenanceCheck.ts'

let subscriptionAppMaintenance: ExtendedIMockSubscription

describe('useAppMaintenanceCheck', () => {
  beforeAll(() => {
    mockGraphQLApi(ApplicationBuildChecksumDocument).willResolve({
      applicationBuildChecksum: {
        applicationBuildChecksum: 'initial-checksum',
      },
    })

    subscriptionAppMaintenance = mockGraphQLSubscription(AppMaintenanceDocument)

    renderComponent(
      {
        template: '<div>App Maintenance Check</div>',
        setup() {
          useAppMaintenanceCheck()
        },
      },
      {
        router: true,
        unmount: false,
      },
    )
  })

  afterEach(() => {
    useNotifications().clearAllNotifications()
    vi.unstubAllGlobals()
  })

  it('reacts to config_updated message', async () => {
    await subscriptionAppMaintenance.next({
      data: {
        appMaintenance: {
          type: EnumAppMaintenanceType.ConfigChanged,
        },
      },
    })

    const { notifications } = useNotifications()

    expect(notifications.value[0].message).toBe(
      'The configuration of Zammad has changed. Please reload at your earliest.',
    )
  })

  it('reacts to app_version message', async () => {
    await subscriptionAppMaintenance.next({
      data: {
        appMaintenance: {
          type: EnumAppMaintenanceType.AppVersion,
        },
      },
    })

    const { notifications } = useNotifications()

    expect(notifications.value[0].message).toBe(
      'A newer version of the app is available. Please reload at your earliest.',
    )
  })

  it('reacts to reload_auto message', async () => {
    await subscriptionAppMaintenance.next({
      data: {
        appMaintenance: {
          type: EnumAppMaintenanceType.RestartAuto,
        },
      },
    })

    const { notifications } = useNotifications()

    expect(notifications.value[0].message).toBe(
      'A newer version of the app is available. Please reload at your earliest.',
    )
  })

  it('reacts to reload_manual message', async () => {
    await subscriptionAppMaintenance.next({
      data: {
        appMaintenance: {
          type: EnumAppMaintenanceType.RestartManual,
        },
      },
    })

    const { notifications } = useNotifications()

    expect(notifications.value[0].message).toBe(
      'A newer version of the app is available. Please reload at your earliest.',
    )
  })

  it('reacts to force_refresh message by reloading without showing a notification', async () => {
    const reloadMock = vi.fn()
    vi.stubGlobal('location', { ...window.location, reload: reloadMock })

    await subscriptionAppMaintenance.next({
      data: {
        appMaintenance: {
          type: EnumAppMaintenanceType.ForceRefresh,
        },
      },
    })

    expect(reloadMock).toHaveBeenCalledOnce()
    expect(useNotifications().notifications.value).toHaveLength(0)
  })

  it('does not raise unhandled exceptions if the payload structure is wrong', async (context) => {
    context.skipConsole = true

    vi.spyOn(console, 'log').mockClear()

    await subscriptionAppMaintenance.next({
      data: {
        pushMessages: {
          title: null,
          text: null,
        },
      },
    })

    expect(console.log).not.toHaveBeenCalledWith(
      'Uncaught Exception',
      new TypeError("Cannot read properties of undefined (reading 'type')"),
    )
  })
})
