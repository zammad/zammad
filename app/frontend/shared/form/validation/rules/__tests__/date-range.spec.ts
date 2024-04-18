// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { createNode } from '@formkit/core'

import dateRange from '../date-range.ts'

const { rule } = dateRange

describe('date_range', () => {
  it('fails when start or end date is missing', () =>
    expect(
      rule(
        createNode({
          value: ['2024-01-01'],
        }),
      ),
    ).toBe(false))

  it('fails when start or end date is missing', () =>
    expect(
      rule(
        createNode({
          value: ['', '2024-02-01'],
        }),
      ),
    ).toBe(false))

  it('passed when start or end date is in correct order', () =>
    expect(
      rule(
        createNode({
          value: ['2024-02-01', '2024-02-10'],
        }),
      ),
    ).toBe(true))

  it('passed when start and end date is the same', () =>
    expect(
      rule(
        createNode({
          value: ['2024-02-01', '2024-02-01'],
        }),
      ),
    ).toBe(true))

  it('fails when end is before start date', () =>
    expect(
      rule(
        createNode({
          value: ['2024-02-01', '2024-01-10'],
        }),
      ),
    ).toBe(false))
})
