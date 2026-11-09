// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'

import { useEntityAttributesScreen } from '#shared/entities/core/attributes/composables/useEntityAttributesScreen.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

export const useUserEntityAttributesStore = defineStore('userEntityAttributes', () => {
  const { screenAttributes: viewScreenAttributes } = useEntityAttributesScreen(
    EnumObjectManagerObjects.User,
    'view',
  )

  return {
    viewScreenAttributes,
  }
})
