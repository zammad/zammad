// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useObjectLinkTypes } from '../useObjectLinkTypes.ts'

describe('useObjectLinkTypes', () => {
  it('returns link types', async () => {
    const { linkTypes } = useObjectLinkTypes()

    expect(linkTypes).toEqual([
      {
        value: 'normal',
        label: 'Normal',
      },
      {
        value: 'child',
        label: 'Child',
      },
      {
        value: 'parent',
        label: 'Parent',
      },
    ])
  })
})
