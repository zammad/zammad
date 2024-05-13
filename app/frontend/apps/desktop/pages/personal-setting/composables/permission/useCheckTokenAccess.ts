// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'

export const useCheckTokenAccess = () => {
  const { config } = useApplicationStore()

  const canUseAccessToken = computed(() => !!config.api_token_access)

  return {
    canUseAccessToken,
  }
}
