// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'

import { waitForNextTick } from '#tests/support/utils.ts'

import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockUserCurrentDeviceListQuery } from '../graphql/queries/userCurrentDeviceList.mocks.ts'
import { mockUserCurrentDeviceDeleteMutation } from '../graphql/mutations/userCurrentDeviceDelete.mocks.ts'
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
    id: '1',
    name: 'Chrome on Mac',
    fingerprint: 'dummy',
    location: 'Germany, Berlin',
    updatedAt: '2024-02-01T12:00:00Z',
  },
  {
    id: '2',
    name: 'Firefox on Mac',
    fingerprint: 'random',
    location: 'Germany, Frankfurt',
    updatedAt: '2024-01-01T12:00:00Z',
  },
]

const rowContents = [
  [
    'Chrome on Mac This device',
    'Germany, Berlin',
    ['2024-02-01 12:00', '2 months ago'],
  ],
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

    const table = within(view.getByRole('table'))

    expect(table.getAllByRole('columnheader')).toHaveLength(4)

    const tableHeaders = ['Name', 'Location', 'Most recent activity', 'Actions']

    tableHeaders.forEach((header) => {
      expect(
        table.getByRole('columnheader', { name: header }),
      ).toBeInTheDocument()
    })

    expect(
      table.getByRole('cell', { name: 'Chrome on Mac This device' }),
    ).toBeInTheDocument()

    rowContents[0].forEach((content) => {
      if (Array.isArray(content)) {
        const dateTime = table.getByTitle(content[0])
        expect(dateTime).toHaveTextContent(content[1])
      } else {
        expect(table.getByRole('cell', { name: content })).toBeInTheDocument()
      }
    })

    rowContents[1].forEach((content) => {
      if (Array.isArray(content)) {
        const dateTime = table.getByTitle(content[0])
        expect(dateTime).toHaveTextContent(content[1])
      } else {
        expect(table.getByRole('cell', { name: content })).toBeInTheDocument()
      }
    })

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

    rowContents[1].forEach(async (content) => {
      if (Array.isArray(content)) {
        expect(await table.findByTitle(content[0])).not.toBeInTheDocument()
      } else {
        expect(
          await table.findByRole('cell', { name: content }),
        ).not.toBeInTheDocument()
      }
    })
  })

  it('updates the device list when a new device is added', async () => {
    mockUserCurrentDeviceListQuery({ userCurrentDeviceList })

    const view = await visitView('/personal-setting/devices')

    const devicesUpdateSubscription =
      getUserCurrentDevicesUpdatesSubscriptionHandler()

    const table = within(view.getByRole('table'))

    devicesUpdateSubscription.trigger({
      userCurrentDevicesUpdates: {
        devices: [
          ...userCurrentDeviceList,
          {
            id: '3',
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

    newDeviceRowContents.forEach((content) => {
      if (Array.isArray(content)) {
        const dateTime = table.getByTitle(content[0])
        expect(dateTime).toHaveTextContent(content[1])
      } else {
        expect(table.getByRole('cell', { name: content })).toBeInTheDocument()
      }
    })
    expect(
      table.getAllByRole('button', { name: 'Delete this device' }),
    ).toHaveLength(2)
  })
})
