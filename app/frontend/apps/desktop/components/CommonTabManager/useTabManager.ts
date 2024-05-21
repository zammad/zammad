// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import type { Tab } from '#desktop/components/CommonTabManager/types.ts'

export const useTabManager = <T = Tab[] | Tab['key']>() => {
  const activeTab = ref<T>()

  return { activeTab }
}
