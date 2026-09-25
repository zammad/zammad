// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { GraphQLErrorTypes } from '#shared/types/error.ts'

import {
  mockUserCurrentCallerNotificationUpdateMutationError,
  waitForUserCurrentCallerNotificationUpdateMutationCalls,
} from '../../graphql/mutations/userCurrentCallerNotificationUpdate.mocks.ts'
import { useCallerNotificationToggle } from '../useCallerNotificationToggle.ts'

describe('useCallerNotificationToggle', () => {
  it('reads the state from the personal settings of the current user', () => {
    mockUserCurrent({ personalSettings: { callerNotificationEnabled: true } })

    expect(useCallerNotificationToggle().isEnabled.value).toBe(true)
  })

  it('is off while the caller notification is switched off', () => {
    mockUserCurrent({ personalSettings: { callerNotificationEnabled: false } })

    expect(useCallerNotificationToggle().isEnabled.value).toBe(false)
  })

  it('switches the state and persists it', async () => {
    mockUserCurrent({ personalSettings: { callerNotificationEnabled: true } })

    const { isEnabled, setEnabled } = useCallerNotificationToggle()

    setEnabled(false)

    expect(isEnabled.value).toBe(false)

    const calls = await waitForUserCurrentCallerNotificationUpdateMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({ enabled: false })
  })

  it('restores the previous state when the update fails', async () => {
    mockUserCurrent({ personalSettings: { callerNotificationEnabled: true } })
    mockUserCurrentCallerNotificationUpdateMutationError('Update failed', {
      type: GraphQLErrorTypes.UnknownError,
    })

    const { isEnabled, setEnabled } = useCallerNotificationToggle()

    await setEnabled(false)

    expect(isEnabled.value).toBe(true)
  })
})
