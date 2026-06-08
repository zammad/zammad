// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { AdminMenuItem } from '#desktop/components/layout/LayoutSidebar/LeftSidebar/types.ts'

const modules = import.meta.glob<AdminMenuItem>(['./*.ts', '!./index.ts'], {
  eager: true,
  import: 'default',
})

const adminModules = Object.entries(modules).map(([_, module]) => module)

export default adminModules.sort((m1, m2) => m1.order - m2.order)
