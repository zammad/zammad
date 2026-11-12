// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { useChatAccess } from '../useChatAccess.ts'

describe('useChatAccess', () => {
  it('is enabled with the chat setting switched on', () => {
    mockApplicationConfig({ chat: true })

    expect(useChatAccess().isChatEnabled.value).toBe(true)
  })

  it.each([false, null, undefined])('is disabled with the chat setting %s', (chat) => {
    mockApplicationConfig({ chat })

    expect(useChatAccess().isChatEnabled.value).toBe(false)
  })
})
