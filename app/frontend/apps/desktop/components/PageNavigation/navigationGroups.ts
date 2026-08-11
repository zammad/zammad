// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

export interface NavigationGroup {
  key: string
  title: string
  icon: string
  order: number
}

// Shared parent menus of the main navigation, one file per group. An addon adds
//   a group by dropping its own file in here, and joins an existing one by
//   pointing `meta.navigationGroup` at its key — so a group is defined exactly
//   once, no matter how many independently installed addons contribute entries
//   to it. Its members are unknown to it, they find it by key.
// The groups directory contains group definitions only; every TypeScript file
//   in it must default-export a NavigationGroup.
const groupModules = import.meta.glob<NavigationGroup>('./groups/*.ts', {
  eager: true,
  import: 'default',
})

export const navigationGroups = Object.values(groupModules)
