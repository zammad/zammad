// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createUuid } from './createUuid.ts'

// Kept in memory only, a duplicated browser tab must not share it via the session storage.
export const browserTabId = createUuid()
