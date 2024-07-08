// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { AddMenuItem } from '#desktop/components/layout/LayoutSidebar/LeftSidebar/types.ts'

const modules = import.meta.glob<AddMenuItem>(['./*.ts', '!./index.ts'], {
  eager: true,
  import: 'default',
})

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const addModules = Object.entries(modules).map(([_, module]) => module)

export default addModules.sort((m1, m2) => m1.order - m2.order)
