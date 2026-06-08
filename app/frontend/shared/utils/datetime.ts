// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { addHours, addMinutes, format, formatISO } from 'date-fns'

// export const validDateTime = (value: string) =>
//   !Number.isNaN(Date.parse(String(value)))

export const validDateTime = (value: string) => {
  const dateTimeRegex =
    /^(?:\d{4}-\d{2}-\d{2}|(?:\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)|(?:\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} UTC))$/

  if (!dateTimeRegex.test(value)) return false

  return !Number.isNaN(Date.parse(String(value)))
}

export const isDateString = (value: string) => {
  const dateRegex = /^\d{4}-\d{2}-\d{2}$/

  return dateRegex.test(value)
}

// Calculate a timestamp with a difference from now, the unit can be either in minutes or hours,
//   the return format can be either in iso string or date string (yyyy-MM-dd).
//   Default behavior: minutes, iso
export const getTimestampWithDiff = (
  diff: number,
  unit: 'minutes' | 'hours' = 'minutes',
  returnFormat: 'iso' | 'date' = 'iso',
): string => {
  const now = new Date()

  const result = unit === 'minutes' ? addMinutes(now, diff) : addHours(now, diff)

  if (returnFormat === 'iso') return formatISO(result)
  return format(result, 'yyyy-MM-dd')
}
