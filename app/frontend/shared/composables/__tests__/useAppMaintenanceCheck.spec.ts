// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { useNotifications } from '@shared/components/CommonNotifications'
import { ApplicationBuildChecksumDocument } from '@shared/graphql/queries/applicationBuildChecksum.api'
import { AppMaintenanceDocument } from '@shared/graphql/subscriptions/appMaintenance.api'
import { EnumAppMaintenanceType } from '@shared/graphql/types'
import { renderComponent } from '@tests/support/components'
import {
  type ExtendedIMockSubscription,
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '@tests/support/mock-graphql-api'
import useAppMaintenanceCheck from '../useAppMaintenanceCheck'

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
})
