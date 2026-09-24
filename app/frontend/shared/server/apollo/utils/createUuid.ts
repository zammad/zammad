// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import getUuid from '#shared/utils/getUuid.ts'

// Because "crypto" is only available in secure context we add a fallback.
export const createUuid = (): string => globalThis.crypto?.randomUUID?.() ?? getUuid()
