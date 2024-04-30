// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'

import { mockAccount } from '#tests/support/mock-account.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockAccountDeviceListQuery } from '../graphql/queries/accountDeviceList.mocks.ts'

const generateFingerprintSpy = vi.fn()

vi.mock('#shared/utils/browser.ts', () => {
  return {
    generateFingerprint: () => {
      generateFingerprintSpy()
      return 'dummy'
    },
  }
})

const accountDeviceList = [
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

describe('testing devices a11y view', async () => {
  beforeEach(() => {
    mockAccount({
      firstname: 'John',
      lastname: 'Doe',
    })

    mockPermissions(['user_preferences.device'])

    mockAccountDeviceListQuery({ accountDeviceList })
  })

  it('has no accessibility violations', async () => {
    const view = await visitView('/personal-setting/devices')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
