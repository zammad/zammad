// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { effectScope, ref } from 'vue'

import { waitUntil } from '#tests/support/utils.ts'

import { mockOnlineNotificationSeenGql } from '#shared/composables/__tests__/mocks/online-notification.ts'
import { useOnlineNotificationSeen } from '#shared/composables/useOnlineNotification/useOnlineNotificationSeen.ts'
import type { ObjectWithId } from '#shared/types/utils.ts'

describe('useOnlineNotificationSeen', () => {
  it('calls mutation when object changes', async () => {
    const mockSeen = mockOnlineNotificationSeenGql()
    const object = ref<ObjectWithId | undefined>(undefined)

    effectScope(true).run(() => useOnlineNotificationSeen(object))

    object.value = { id: '2' }

    await waitUntil(() => mockSeen.calls.resolve)

    expect(mockSeen.spies.resolve).toHaveBeenCalledWith({
      objectId: '2',
    })
  })

  it('calls mutation when the object is already there', async () => {
    const mockSeen = mockOnlineNotificationSeenGql()
    const object = ref<ObjectWithId | undefined>({ id: '3' })

    effectScope(true).run(() => useOnlineNotificationSeen(object))

    await waitUntil(() => mockSeen.calls.resolve)

    expect(mockSeen.spies.resolve).toHaveBeenCalledWith({
      objectId: '3',
    })
  })
})
