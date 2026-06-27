// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { isValid, parseISO } from 'date-fns'

import type { FormKitNode } from '@formkit/core'

// Self-heals a reversed date range (`[start, end]` with `start > end`) by
// swapping the bounds instead of letting an invalid range through. Registered
// as a node feature, so it runs on FormKit's input hook for *every* value the
// field receives — the calendar, typed text, and external/programmatic
// `node.input` (including the initial/restored value) — from a single point,
// with no watcher or per-path duplication.
//
// `parseISO` parses both value formats the field emits: `yyyy-MM-dd` (date,
// itself valid ISO) and full ISO (datetime), so the comparison is correct and
// DST-safe without needing the field's `valueFormat`.
const healDateRange = (node: FormKitNode) => {
  node.hook.input((payload, next) => {
    if (Array.isArray(payload)) {
      const [start, end] = payload

      if (typeof start === 'string' && typeof end === 'string') {
        const startDate = parseISO(start)
        const endDate = parseISO(end)

        if (isValid(startDate) && isValid(endDate) && startDate > endDate) {
          return next([end, start])
        }
      }
    }

    return next(payload)
  })
}

export default healDateRange
