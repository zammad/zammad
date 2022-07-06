// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { useNotifications } from '@shared/components/CommonNotifications'
import { ApplicationBuildChecksumDocument } from '@shared/graphql/queries/applicationBuildChecksum.api'
import { AppMaintenanceDocument } from '@shared/graphql/subscriptions/appMaintenance.api'
import { AppMaintenanceType } from '@shared/graphql/types'
import { renderComponent } from '@tests/support/components'
import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '@tests/support/mock-graphql-api'
import { IMockSubscription } from 'mock-apollo-client'
import useAppMaintenanceCheck from '../useAppMaintenanceCheck'

let subscriptionAppMaintenance: IMockSubscription

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

  it('reacts to config_updated message', () => {
    subscriptionAppMaintenance.next({
      data: {
        appMaintenance: {
          type: AppMaintenanceType.ConfigChanged,
        },
      },
    })

    const { notifications } = useNotifications()

    expect(notifications.value[0].message).toBe(
      'The configuration of Zammad has changed. Please reload at your earliest.',
    )
  })

  it('reacts to app_version message', () => {
    subscriptionAppMaintenance.next({
      data: {
        appMaintenance: {
          type: AppMaintenanceType.AppVersion,
        },
      },
    })

    const { notifications } = useNotifications()

    expect(notifications.value[0].message).toBe(
      'A newer version of the app is available. Please reload at your earliest.',
    )
  })

  it('reacts to reload_auto message', () => {
    subscriptionAppMaintenance.next({
      data: {
        appMaintenance: {
          type: AppMaintenanceType.RestartAuto,
        },
      },
    })

    const { notifications } = useNotifications()

    expect(notifications.value[0].message).toBe(
      'A newer version of the app is available. Please reload at your earliest.',
    )
  })

  it('reacts to reload_manual message', () => {
    subscriptionAppMaintenance.next({
      data: {
        appMaintenance: {
          type: AppMaintenanceType.RestartManual,
        },
      },
    })

    const { notifications } = useNotifications()

    expect(notifications.value[0].message).toBe(
      'A newer version of the app is available. Please reload at your earliest.',
    )
  })
})
