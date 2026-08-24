// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'
import { useRoute } from 'vue-router'

import type { BreadcrumbItem } from '#desktop/components/CommonBreadcrumb/types.ts'

import { personalSettingItems } from '../views/PersonalSetting/plugins/index.ts'

/**
 * Builds the breadcrumb of the current personal setting page from its plugin
 * definition, so that the category and the page label stay in sync with the
 * secondary sidebar navigation.
 *
 * The category is contextual information without a route of its own, therefore
 * it is intentionally rendered as plain text instead of a link.
 */
export const useBreadcrumb = () => {
  const route = useRoute()

  const plugin = computed(() =>
    Object.values(personalSettingItems)
      .flat()
      .find((item) => item.route.name === route.name),
  )

  const breadcrumbItems = computed<BreadcrumbItem[]>(() => {
    if (!plugin.value) return []

    return [{ label: plugin.value.category.label }, { label: plugin.value.label }]
  })

  return {
    breadcrumbItems,
  }
}
