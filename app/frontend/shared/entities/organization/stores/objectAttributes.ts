// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'

import { useObjectAttributesScreen } from '#shared/entities/object-attributes/composables/useObjectAttributesScreen.ts'
import type { EntityStaticObjectAttributes } from '#shared/entities/object-attributes/types/store.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

export const staticObjectAttributes: EntityStaticObjectAttributes = {
  name: EnumObjectManagerObjects.Organization,
  attributes: [
    {
      name: 'created_by_id',
      display: __('Created by'),
      dataOption: {
        relation: 'User',
      },
      dataType: 'autocomplete',
      isStatic: true,
      isInternal: true,
    },
    {
      name: 'created_at',
      display: __('Created at'),
      dataType: 'datetime',
      isStatic: true,
      isInternal: true,
    },
    {
      name: 'updated_by_id',
      display: __('Updated by'),
      dataOption: {
        relation: 'User',
      },
      dataType: 'autocomplete',
      isStatic: true,
      isInternal: true,
    },
    {
      name: 'updated_at',
      display: __('Updated at'),
      dataType: 'datetime',
      isStatic: true,
      isInternal: true,
    },
  ],
}

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
