// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { isRef } from 'vue'

import { useTabGroup } from '#desktop/components/CommonTabGroup/useTabGroup.ts'

describe('useTabGroup', () => {
  it('test useTabGroup', () => {
    const composable = useTabGroup()
    expect(isRef(composable.activeTab)).toBeTruthy()
  })
})
