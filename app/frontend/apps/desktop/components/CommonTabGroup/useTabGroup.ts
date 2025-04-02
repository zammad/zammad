// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import type { Tab } from '#desktop/components/CommonTabGroup/types.ts'

export const useTabGroup = <T = Tab[] | Tab['key']>() => {
  const activeTab = ref<T>()

  return { activeTab }
}
