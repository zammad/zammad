// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'

export const useChatAccess = () => {
  const application = useApplicationStore()

  const isChatEnabled = computed(() => Boolean(application.config.chat))

  return { isChatEnabled }
}
