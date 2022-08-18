// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import { useObjectManagerAttributes } from '@shared/entities/object-manager/composables/useObjectManagerAttributes'
import { EnumObjectManagerObjects } from '@shared/graphql/types'

export const useOrganizationObjectManagerAttributes = defineStore(
  'organizationObjectAttributes',
  () => {
    const attributes = useObjectManagerAttributes(
      EnumObjectManagerObjects.Organization,
      'view',
    )

    return {
      ...attributes,
    }
  },
)
