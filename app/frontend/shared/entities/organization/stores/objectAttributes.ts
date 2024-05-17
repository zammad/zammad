// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'

import { useObjectAttributesScreen } from '#shared/entities/object-attributes/composables/useObjectAttributesScreen.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

export const useOrganizationObjectAttributesStore = defineStore(
  'organizationObjectAttributes',
  () => {
    const { screenAttributes: viewScreenAttributes } =
      useObjectAttributesScreen(EnumObjectManagerObjects.Organization, 'view')

    return {
      viewScreenAttributes,
    }
  },
)
