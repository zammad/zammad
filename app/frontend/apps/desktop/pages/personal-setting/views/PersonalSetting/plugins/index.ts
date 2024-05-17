// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { NavigationMenuCategory } from '#desktop/components/NavigationMenu/types.ts'

import type { PersonalSettingPlugin } from './types.ts'

const plugins = import.meta.glob<PersonalSettingPlugin>(
  ['./**/*.ts', '!./**/index.ts', '!./types.ts', '!./__tests__/**/*.ts'],
  {
    eager: true,
    import: 'default',
  },
)

const categories: NavigationMenuCategory[] = []
const categorizedItems: Record<string, PersonalSettingPlugin[]> = {}

Object.values(plugins).forEach((plugin) => {
  if (
    !categories.find((category) => category.label === plugin.category.label)
  ) {
    categories.push(plugin.category)
  }

  return categories.sort((c1, c2) => c1.order - c2.order)
})

Object.values(plugins).forEach((plugin) => {
  const categoryLabel = plugin.category.label
  if (!categorizedItems[categoryLabel]) {
    categorizedItems[categoryLabel] = []
  }

  categorizedItems[categoryLabel].push(plugin)
  categorizedItems[categoryLabel].sort((p1, p2) => p1.order - p2.order)

  return categorizedItems
})

export const personalSettingCategories = categories
export const personalSettingItems = categorizedItems

export const personalSettingRoutes = Object.values(plugins).map(
  (plugin) => plugin.route,
)
