// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

export interface AvatarMenuPlugin extends MenuItem {
  order: number
}

const pluginModules = import.meta.glob<AvatarMenuPlugin>(
  ['./**/*.ts', '!./**/index.ts', '!./__tests__/**/*.ts'],
  {
    eager: true,
    import: 'default',
  },
)

export const avatarMenuPlugins = Object.values(pluginModules).sort(
  (p1, p2) => p1.order - p2.order,
)

export const avatarMenuItems = avatarMenuPlugins.map(
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  ({ order, ...item }) => item,
)
