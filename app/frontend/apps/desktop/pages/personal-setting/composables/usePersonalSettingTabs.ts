// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'
import { useRoute } from 'vue-router'

import { useSessionStore } from '#shared/stores/session.ts'

import type { NavigationTab } from '#desktop/components/CommonTabs/types.ts'

import {
  personalSettingCategories,
  personalSettingItems,
} from '../views/PersonalSetting/plugins/index.ts'

export const usePersonalSettingTabs = () => {
  const session = useSessionStore()
  const route = useRoute()

  const tabs = computed<NavigationTab[]>(() =>
    personalSettingCategories
      .flatMap((category) => personalSettingItems[category.label] || [])
      .filter((plugin) => {
        if (
          plugin.route.meta?.requiredPermission &&
          !session.hasPermission(plugin.route.meta.requiredPermission)
        )
          return false

        if (plugin.show) return plugin.show(session.user)

        return true
      })
      .map((plugin) => ({
        label: plugin.label,
        key: plugin.route.name,
        link: { name: plugin.route.name },
      })),
  )

  const activeTab = computed(() => (typeof route.name === 'string' ? route.name : ''))

  return {
    tabs,
    activeTab,
  }
}
