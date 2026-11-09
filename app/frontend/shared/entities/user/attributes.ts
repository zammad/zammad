// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { EntityClientAttributes } from '#shared/entities/core/attributes/types/store.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

export const clientAttributes: EntityClientAttributes = {
  name: EnumObjectManagerObjects.User,
  attributes: [
    {
      name: 'created_by_id',
      display: __('Created by'),
      dataOption: {
        relation: 'User',
      },
      id: 'created_by_id-1',
      dataType: 'autocompletion_ajax',
      isStatic: true,
      isInternal: true,
    },
    {
      name: 'created_at',
      display: __('Created at'),
      dataType: 'datetime',
      id: 'created_at-1',
      isStatic: true,
      isInternal: true,
    },
    {
      name: 'updated_by_id',
      display: __('Updated by'),
      dataOption: {
        relation: 'User',
      },
      dataType: 'autocompletion_ajax',
      id: 'updated_by_id-1',
      isStatic: true,
      isInternal: true,
    },
    {
      name: 'updated_at',
      display: __('Updated at'),
      id: 'updated_at-1',
      dataType: 'datetime',
      isStatic: true,
      isInternal: true,
    },
  ],
}
