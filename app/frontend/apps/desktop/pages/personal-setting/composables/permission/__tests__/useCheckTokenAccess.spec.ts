// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { useCheckTokenAccess } from '../useCheckTokenAccess.ts'

describe('useCheckTokenAccess', () => {
  it('can use access token', () => {
    mockApplicationConfig({
      api_token_access: true,
    })

    const { canUseAccessToken } = useCheckTokenAccess()

    expect(canUseAccessToken.value).toBe(true)
  })

  it('can not use access token when api token access is disabled', async () => {
    mockApplicationConfig({
      api_token_access: false,
    })

    const { canUseAccessToken } = useCheckTokenAccess()

    expect(canUseAccessToken.value).toBe(false)
  })
})
