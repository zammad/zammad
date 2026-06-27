// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createNode } from '@formkit/core'

import healDateRange from '#shared/components/Form/fields/FieldDate/healDateRange.ts'

// Feed `value` through a node carrying the feature and return what it committed.
const committed = (value: unknown) => {
  const node = createNode()
  healDateRange(node)
  node.input(value, false)

  return node.value
}

describe('healDateRange', () => {
  it('swaps a reversed range', () => {
    expect(committed(['2021-04-28', '2021-04-14'])).toEqual(['2021-04-14', '2021-04-28'])
  })

  it('swaps a reversed datetime (ISO) range', () => {
    expect(committed(['2021-04-28T10:00:00Z', '2021-04-14T10:00:00Z'])).toEqual([
      '2021-04-14T10:00:00Z',
      '2021-04-28T10:00:00Z',
    ])
  })

  it('leaves an ordered range unchanged', () => {
    expect(committed(['2021-04-14', '2021-04-28'])).toEqual(['2021-04-14', '2021-04-28'])
  })

  it('leaves incomplete, single, and non-range values unchanged', () => {
    expect(committed(['2021-04-14', null])).toEqual(['2021-04-14', null])
    expect(committed('2021-04-14')).toBe('2021-04-14')
    expect(committed(null)).toBeNull()
  })
})
