// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { ShallowRef } from 'vue'

export interface CollapseOptions {
  name?: string
  isCollapsed?: ShallowRef<boolean>
}

export interface CollapseCallbacks {
  collapse: () => void
  expand: () => void
}
