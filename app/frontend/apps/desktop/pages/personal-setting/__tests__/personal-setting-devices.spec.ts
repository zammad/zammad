// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import {
  checkSimpleTableContent,
  checkSimpleTableHeader,
} from '#tests/support/components/checkSimpleTableContent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockUserCurrentDeviceDeleteMutation } from '../graphql/mutations/userCurrentDeviceDelete.mocks.ts'
import { mockUserCurrentDeviceListQuery } from '../graphql/queries/userCurrentDeviceList.mocks.ts'
import { getUserCurrentDevicesUpdatesSubscriptionHandler } from '../graphql/subscriptions/userCurrentDevicesUpdates.mocks.ts'

vi.hoisted(() => {
  vi.setSystemTime(new Date('2024-04-25T10:00:00Z'))
})

const generateFingerprintSpy = vi.fn()

vi.mock('#shared/utils/browser.ts', () => {
  return {
    generateFingerprint: () => {
      generateFingerprintSpy()
      return 'dummy'
    },
  }
})

const userCurrentDeviceList = [
  {
    id: convertToGraphQLId('UserDevice', 1),
    name: 'Chrome on Mac',
    fingerprint: 'dummy',
    location: 'Germany, Berlin',
    updatedAt: '2024-02-01T12:00:00Z',
  },
  {
    id: convertToGraphQLId('UserDevice', 2),
    name: 'Firefox on Mac',
    fingerprint: 'random',
    location: 'Germany, Frankfurt',
    updatedAt: '2024-01-01T12:00:00Z',
  },
]

const rowContents = [
  ['Chrome on Mac', 'Germany, Berlin', ['2024-02-01 12:00', '2 months ago']],
  [
    'Firefox on Mac',
    'Germany, Frankfurt',
    ['2024-01-01 12:00', '3 months ago'],
  ],
]

describe('devices personal settings', () => {
  beforeEach(() => {
    mockUserCurrent({
      firstname: 'John',
      lastname: 'Doe',
    })

    mockPermissions(['user_preferences.device'])
  })

  afterAll(() => {
    vi.useRealTimers()
  })

  it('shows the list of all devices', async () => {
    mockUserCurrentDeviceListQuery({ userCurrentDeviceList })

    const view = await visitView('/personal-setting/devices')

    const tableHeaders = ['Name', 'Location', 'Most recent activity', 'Actions']
    checkSimpleTableHeader(view, tableHeaders)
    checkSimpleTableContent(view, rowContents)

    const table = within(view.getByRole('table'))

    expect(
      within(table.getAllByRole('row')[0]).getAllByRole('cell')[0],
    ).toHaveTextContent(/This device/)

    expect(
      table.getAllByRole('button', { name: 'Delete this device' }),
    ).toHaveLength(1)
  })

  it('can delete a device', async () => {
    mockUserCurrentDeviceListQuery({ userCurrentDeviceList })

    const view = await visitView('/personal-setting/devices')

    const table = within(view.getByRole('table'))

    const deleteButton = table.getByRole('button', {
      name: 'Delete this device',
    })

    mockUserCurrentDeviceDeleteMutation({
      userCurrentDeviceDelete: {
        success: true,
      },
    })

    await view.events.click(deleteButton)

    await waitForNextTick()

    expect(
      await view.findByRole('dialog', { name: 'Delete Object' }),
    ).toBeInTheDocument()

    await view.events.click(view.getByRole('button', { name: 'Delete Object' }))

    checkSimpleTableContent(view, [rowContents[0]])
  })

  it('updates the device list when a new device is added', async () => {
    mockUserCurrentDeviceListQuery({ userCurrentDeviceList })

    const view = await visitView('/personal-setting/devices')

    const devicesUpdateSubscription =
      getUserCurrentDevicesUpdatesSubscriptionHandler()

    devicesUpdateSubscription.trigger({
      userCurrentDevicesUpdates: {
        devices: [
          ...userCurrentDeviceList,
          {
            id: convertToGraphQLId('UserDevice', 3),
            name: 'Safari on Mac',
            fingerprint: 'new',
            location: 'Germany, Munich',
            updatedAt: '2024-04-25T09:59:59Z',
          },
        ],
      },
    })

    await waitForNextTick()

    const newDeviceRowContents = [
      'Safari on Mac',
      'Germany, Munich',
      ['2024-04-25 09:59', 'just now'],
    ]

    checkSimpleTableContent(view, [...rowContents, newDeviceRowContents])

    const table = within(view.getByRole('table'))
    expect(
      table.getAllByRole('button', { name: 'Delete this device' }),
    ).toHaveLength(2)
  })
})
