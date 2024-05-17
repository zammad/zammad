// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'

export const useLogoUrl = () => {
  const application = useApplicationStore()

  const logoUrl = computed(() => {
    return `/api/v1/system_assets/product_logo/${application.config.product_logo}`
  })

  return { logoUrl }
}
