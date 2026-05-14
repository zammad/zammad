// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { Operator } from '../types.ts'

const modules = import.meta.glob<Operator>(['./*.ts', '!./index.ts'], {
  eager: true,
  import: 'default',
})

export const operators: Record<string, Operator> = Object.fromEntries(
  Object.values(modules).map((operator) => [operator.name, operator]),
)
