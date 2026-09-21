// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createNode } from '@formkit/core'

import normalizeDateValue from '#shared/components/Form/fields/FieldDate/normalizeDateValue.ts'

// Feed `value` through a node carrying the feature and return what it committed.
const committed = (value: unknown) => {
  const node = createNode()
  normalizeDateValue(node)
  node.input(value, false)

  return node.value
}

// The same for the value the node is created with, which `nodeInit` dispatches through the input
//   hook only after it has applied the plugins - so the feature has to be one of them here.
const committedAtCreation = (value: unknown) =>
  createNode({ plugins: [normalizeDateValue], value }).value

describe('normalizeDateValue', () => {
  it('drops the milliseconds the calendar emits', () => {
    expect(committed('2026-09-23T10:32:00.000Z')).toBe('2026-09-23T10:32:00Z')
  })

  it('rewrites the local offset the text input emits to UTC', () => {
    expect(committed('2026-09-23T13:32:00+03:00')).toBe('2026-09-23T10:32:00Z')
  })

  it('leaves a value already in that spelling untouched', () => {
    expect(committed('2026-09-23T10:32:00Z')).toBe('2026-09-23T10:32:00Z')
  })

  it('normalizes both bounds of a range', () => {
    expect(committed(['2026-09-23T13:32:00+03:00', '2026-09-24T10:32:00.000Z'])).toEqual([
      '2026-09-23T10:32:00Z',
      '2026-09-24T10:32:00Z',
    ])
  })

  // The baseline the field's own later values are compared against. Normalizing only what the user
  //   produces would leave it un-normalized, which is the bug itself.
  it('normalizes the value the field is opened with', () => {
    expect(committedAtCreation('2026-09-23T13:32:00+03:00')).toBe('2026-09-23T10:32:00Z')
  })

  it('leaves a date, an unparseable value and a non-string unchanged', () => {
    expect(committed('2026-09-23')).toBe('2026-09-23')
    expect(committed('not a date at all T')).toBe('not a date at all T')
    expect(committed(null)).toBeNull()
  })
})
