// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import { useObjectAttributesScreen } from '#shared/entities/object-attributes/composables/useObjectAttributesScreen.ts'

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
