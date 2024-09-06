// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { AdminMenuItem } from '#desktop/components/layout/LayoutSidebar/LeftSidebar/types.ts'

export default {
  order: 100,
  key: 'admin',
  label: __('Administration'),
  permission: ['admin.*'],
  variant: 'neutral',
  icon: 'gear',
  link: '/#manage', // This is a transition solution, the actual link will be different
} as AdminMenuItem
