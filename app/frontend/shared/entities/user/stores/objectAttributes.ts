// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import { useObjectAttributesScreen } from '@shared/entities/object-attributes/composables/useObjectAttributesScreen'
import { EnumObjectManagerObjects } from '@shared/graphql/types'

export const useUserObjectAttributesStore = defineStore(
  'userObjectAttributes',
  () => {
    const { screenAttributes: viewScreenAttributes } =
      useObjectAttributesScreen(EnumObjectManagerObjects.User, 'view')

    return {
      viewScreenAttributes,
    }
  },
)
