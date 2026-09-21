// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { isValid, parseISO } from 'date-fns'

import type { FormKitNode } from '@formkit/core'

// UTC and whole seconds, which is what `GraphQL::Types::ISO8601DateTime` seeds the form with
// and all the form is able to express anyway.
export const formatDateTimeValue = (date: Date) => `${date.toISOString().slice(0, 19)}Z`

const normalizeDateTimeValue = (value: string) => {
  // A date carries no time and is already written one way (`yyyy-MM-dd`).
  if (!value.includes('T')) return value

  const date = parseISO(value)
  if (!isValid(date)) return value

  return formatDateTimeValue(date)
}

// One spelling for a datetime value, whoever produced it. The same instant reaches the field
// written three ways — the server seeds `2026-09-23T10:32:00Z`, the calendar emits
// `toISOString()` with its milliseconds, the text input `formatISO()` with the local offset —
// and FormKit compares the strings rather than the instants (`dirtyBehavior: 'compare'`), so a
// field put back to the value it was opened with still reads as changed.
//
// A node feature like healDateRange, for the same reason: the input hook sees every value the
// field receives, the initial one included. Normalising only what the user produces would leave
// it compared against an un-normalised baseline, which is the bug itself.
const normalizeDateValue = (node: FormKitNode) => {
  node.hook.input((payload, next) => {
    if (typeof payload === 'string') return next(normalizeDateTimeValue(payload))

    if (Array.isArray(payload)) {
      return next(
        payload.map((value) => (typeof value === 'string' ? normalizeDateTimeValue(value) : value)),
      )
    }

    return next(payload)
  })
}

export default normalizeDateValue
