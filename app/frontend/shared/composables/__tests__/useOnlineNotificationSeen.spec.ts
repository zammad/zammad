// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'
import { mockOnlineNotificationSeenGql } from '@shared/composables/__tests__/mocks/online-notification'
import type { ObjectWithId } from '@shared/types/utils'
import { waitUntil } from '@tests/support/utils'
import { useOnlineNotificationSeen } from '../useOnlineNotificationSeen'

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
