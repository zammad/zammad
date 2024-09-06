// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'

export const useBaseUrl = () => {
  const application = useApplicationStore()

  const baseUrl = computed(() => {
    const { http_type: httpType, fqdn } = application.config

    if (!fqdn || fqdn === 'zammad.example.com') return window.location.origin

    return `${httpType}://${fqdn}`
  })

  return {
    baseUrl,
  }
}
