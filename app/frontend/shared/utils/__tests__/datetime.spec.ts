// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { validDateTime, isDateString } from '../datetime.ts'

describe('validDateTime', () => {
  it('is a valid date with time', () => {
    expect(validDateTime('2024-10-10T06:00:00Z')).toBe(true)
  })

  it('is a valid date', () => {
    expect(validDateTime('2024-10-10')).toBe(true)
  })

  it('is a valid date with time', () => {
    expect(validDateTime('2024-02-20 14:29:07 UTC')).toBe(true)
  })

  it('is a invalid date', () => {
    expect(validDateTime('2024+10-10T06:00:00Z')).toBe(false)
  })

  it('is also an invalid date', () => {
    expect(validDateTime('Test 456')).toBe(false)
  })
})

describe('isDateString', () => {
  it('is a valid date string only', () => {
    expect(isDateString('2024-10-10')).toBe(true)
  })

  it('is a valid date', () => {
    expect(isDateString('2024-10-10T06:00:00Z')).toBe(false)
  })
})
