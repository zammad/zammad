// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import timezoneMock from 'timezone-mock'
import { absoluteDateTime as absDT, relativeDateTime as relDT } from '../dates'
import { Translator } from '../translator'

describe('Dates', () => {
  const dateUS = 'mm/dd/yyyy'
  const dateTimeUS = 'mm/dd/yyyy l:MM P'

  it('translates absolute dates correctly', () => {
    // UTC is default
    expect(absDT('2021-04-09T10:11:12Z', dateUS)).toBe('04/09/2021')
    expect(absDT('2021-04-09T10:11:12Z', dateTimeUS)).toBe(
      '04/09/2021 10:11 am',
    )
    expect(absDT('2021-04-09T22:11:12Z', dateTimeUS)).toBe(
      '04/09/2021 10:11 pm',
    )

    // Switch to US/Eastern
    timezoneMock.register('US/Eastern', global)
    expect(absDT('2021-04-09T10:11:12Z', dateUS)).toBe('04/09/2021')
    expect(absDT('2021-04-09T10:11:12Z', dateTimeUS)).toBe(
      '04/09/2021  6:11 am',
    )
    expect(absDT('2021-04-09T22:11:12Z', dateTimeUS)).toBe(
      '04/09/2021  6:11 pm',
    )
    timezoneMock.unregister(global)
  })

  it('handles UTC date strings', () => {
    expect(absDT('2021-04-09 10:11:12 UTC', dateUS)).toBe('04/09/2021')
  })

  it('shows relative dates correctly', () => {
    const b = new Date('2021-04-09T10:11:12Z')
    const t = new Translator()

    expect(relDT('2021-04-09T10:11:12Z', b, t)).toBe('just now')

    expect(relDT('2021-04-09T10:12:11Z', b, t)).toBe('just now')
    expect(relDT('2021-04-09T10:12:12Z', b, t)).toBe('in 1 minute')
    expect(relDT('2021-04-09T10:13:12Z', b, t)).toBe('in 2 minutes')
    expect(relDT('2021-04-09T11:10:12Z', b, t)).toBe('in 59 minutes')
    expect(relDT('2021-04-09T10:10:13Z', b, t)).toBe('just now')
    expect(relDT('2021-04-09T10:10:12Z', b, t)).toBe('1 minute ago')
    expect(relDT('2021-04-09T10:09:12Z', b, t)).toBe('2 minutes ago')
    expect(relDT('2021-04-09T09:12:12Z', b, t)).toBe('59 minutes ago')

    expect(relDT('2021-04-09T09:11:12Z', b, t)).toBe('1 hour ago')
    expect(relDT('2021-04-08T11:11:12Z', b, t)).toBe('23 hours ago')
    expect(relDT('2021-04-09T11:11:12Z', b, t)).toBe('in 1 hour')
    expect(relDT('2021-04-10T09:11:12Z', b, t)).toBe('in 23 hours')

    expect(relDT('2021-04-08T10:11:12Z', b, t)).toBe('1 day ago')
    expect(relDT('2021-04-03T10:11:12Z', b, t)).toBe('6 days ago')
    expect(relDT('2021-04-10T10:11:12Z', b, t)).toBe('in 1 day')
    expect(relDT('2021-04-15T10:11:12Z', b, t)).toBe('in 6 days')

    expect(relDT('2021-04-02T10:11:12Z', b, t)).toBe('1 week ago')
    expect(relDT('2021-03-12T10:11:12Z', b, t)).toBe('4 weeks ago')
    expect(relDT('2021-04-16T10:11:12Z', b, t)).toBe('in 1 week')
    expect(relDT('2021-05-07T10:11:12Z', b, t)).toBe('in 4 weeks')

    expect(relDT('2021-03-09T10:11:12Z', b, t)).toBe('1 month ago')
    expect(relDT('2020-04-19T10:11:12Z', b, t)).toBe('11 months ago')
    expect(relDT('2021-05-09T10:11:12Z', b, t)).toBe('in 1 month')
    expect(relDT('2022-03-09T10:11:12Z', b, t)).toBe('in 11 months')

    expect(relDT('2020-04-09T10:11:12Z', b, t)).toBe('1 year ago')
    expect(relDT('2000-04-09T10:11:12Z', b, t)).toBe('21 years ago')
    expect(relDT('2022-04-09T10:11:12Z', b, t)).toBe('in 1 year')
    expect(relDT('2042-04-09T10:11:12Z', b, t)).toBe('in 21 years')
  })
})
