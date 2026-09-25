// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { email as emailValidation } from '@formkit/rules'

import type { FormKitNode } from '@formkit/core'

export const emailFilterValueValidator = (filter: string) =>
  emailValidation({ value: filter } as FormKitNode)

// Very rudimentary validator for the E.164 telephone number format, i.e. +499876543210.
export const phoneFilterValueValidator = (filter: string) => /^\+?[1-9]\d+$/.test(filter)

// A number the way people write it down, i.e. +49 (0)30 123-456: separators allowed, at least six digits.
export const formattedPhoneFilterValueValidator = (filter: string) =>
  /^\+?[\d\s\-()/.]+$/.test(filter) && (filter.match(/\d/g)?.length ?? 0) >= 6
