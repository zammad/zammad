// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { isRef } from 'vue'

import { useTabManager } from '#desktop/components/CommonTabManager/useTabManager.ts'

describe('useTabManager', () => {
  it('test useTabManager', () => {
    const composable = useTabManager()
    expect(isRef(composable.activeTab)).toBeTruthy()
  })
})
