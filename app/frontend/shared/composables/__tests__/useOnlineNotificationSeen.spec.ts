// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { waitUntil } from '#tests/support/utils.ts'

import { mockOnlineNotificationSeenGql } from '#shared/composables/__tests__/mocks/online-notification.ts'
import type { ObjectWithId } from '#shared/types/utils.ts'

import { useOnlineNotificationSeen } from '../useOnlineNotificationSeen.ts'

describe('useOnlineNotificationSeen', () => {
  it('calls mutation when object changes', async () => {
    const mockSeen = mockOnlineNotificationSeenGql()
    const object = ref<ObjectWithId | undefined>(undefined)

    useOnlineNotificationSeen(object)

    object.value = { id: '2' }

    await waitUntil(() => mockSeen.calls.resolve)

    expect(mockSeen.spies.resolve).toHaveBeenCalledWith({
      objectId: '2',
    })
  })
})
