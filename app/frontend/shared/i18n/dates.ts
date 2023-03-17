// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Translator } from './translator'

const formatNumber = (num: number, digits: number): string => {
  let result = num.toString()
  while (result.length < digits) {
    result = `0${result}`
  }
  return result
}

export const absoluteDateTime = (
  dateTimeString: string,
  template: string,
): string => {
  let date = new Date(dateTimeString)
  // On firefox the Date constructor does not recongise date format that
  // ends with UTC, instead it returns a NaN (Invalid Date Format) this
  // block serves as polyfill to support time format that ends UTC in firefox
  if (Number.isNaN(date.getDate())) {
    // works for only time string with this format: 2021-02-08 09:13:20 UTC
    const timeArray = dateTimeString.match(/\d+/g) || []
    const [y, m, d, H, M] = timeArray.map((value) => {
      return parseInt(value, 10)
    })
    date = new Date(Date.UTC(y, m - 1, d, H, M))
  }

  const d = date.getDate()
  const m = date.getMonth() + 1
  const H = date.getHours()
  const yfull = date.getFullYear().toString()
  const yshort = yfull.substring(yfull.length - 2)
  const lnum = ((H + 11) % 12) + 1
  const l = lnum < 10 ? ` ${lnum}` : lnum

  return template
    .replace('dd', formatNumber(d, 2))
    .replace('d', d.toString())
    .replace('mm', formatNumber(m, 2))
    .replace('m', m.toString())
    .replace('yyyy', yfull)
    .replace('yy', yshort)
    .replace('SS', formatNumber(date.getSeconds(), 2))
    .replace('MM', formatNumber(date.getMinutes(), 2))
    .replace('HH', formatNumber(H, 2))
    .replace('l', l.toString())
    .replace('P', H >= 12 ? 'pm' : 'am')
}

const durationMinute = 60
const durationHour = 60 * durationMinute
const durationDay = 24 * durationHour
const durationWeek = 7 * durationDay
const durationMonth = 30 * durationDay
const durationYear = 356 * durationDay

enum Direction {
  Past,
  Future,
}

type DurationMessages = {
  duration: number
  pastSingular: string
  pastPlural: string
  futureSingular: string
  futurePlural: string
}

const durations: DurationMessages[] = [
  {
    duration: durationYear,
    pastSingular: __('1 year ago'),
    pastPlural: __('%s years ago'),
    futureSingular: __('in 1 year'),
    futurePlural: __('in %s years'),
  },
  {
    duration: durationMonth,
    pastSingular: __('1 month ago'),
    pastPlural: __('%s months ago'),
    futureSingular: __('in 1 month'),
    futurePlural: __('in %s months'),
  },
  {
    duration: durationWeek,
    pastSingular: __('1 week ago'),
    pastPlural: __('%s weeks ago'),
    futureSingular: __('in 1 week'),
    futurePlural: __('in %s weeks'),
  },
  {
    duration: durationDay,
    pastSingular: __('1 day ago'),
    pastPlural: __('%s days ago'),
    futureSingular: __('in 1 day'),
    futurePlural: __('in %s days'),
  },
  {
    duration: durationHour,
    pastSingular: __('1 hour ago'),
    pastPlural: __('%s hours ago'),
    futureSingular: __('in 1 hour'),
    futurePlural: __('in %s hours'),
  },
  {
    duration: durationMinute,
    pastSingular: __('1 minute ago'),
    pastPlural: __('%s minutes ago'),
    futureSingular: __('in 1 minute'),
    futurePlural: __('in %s minutes'),
  },
]

export const relativeDateTime = (
  dateTimeString: string,
  baseDate: Date,
  translator: Translator,
): string => {
  const date = new Date(dateTimeString)
  let diffSeconds = (baseDate.getTime() - date.getTime()) / 1000

  const direction: Direction =
    diffSeconds > -1 ? Direction.Past : Direction.Future

  diffSeconds = Math.abs(diffSeconds)

  for (const duration of durations) {
    if (diffSeconds >= duration.duration) {
      const count = Math.floor(diffSeconds / duration.duration)
      if (direction === Direction.Past) {
        return count === 1
          ? translator.translate(duration.pastSingular)
          : translator.translate(duration.pastPlural, count)
      }
      return count === 1
        ? translator.translate(duration.futureSingular)
        : translator.translate(duration.futurePlural, count)
    }
  }

  return translator.translate('just now')
}

export const getDateFormat = (translator: Translator) => {
  return translator.lookup('FORMAT_DATE') || 'yyyy-mm-dd'
}

export const getDateTimeFormat = (translator: Translator) => {
  return translator.lookup('FORMAT_DATETIME') || 'yyyy-mm-dd HH:MM'
}
