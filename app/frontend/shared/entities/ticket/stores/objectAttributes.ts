// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { EntityStaticObjectAttributes } from '#shared/entities/object-attributes/types/store.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

export const staticObjectAttributes: EntityStaticObjectAttributes = {
  name: EnumObjectManagerObjects.Ticket,
  attributes: [
    {
      name: 'number',
      display: '#',
      dataType: 'input',
      isStatic: true,
      isInternal: true,
    },
    {
      name: 'time_unit',
      display: __('Accounted Time'),
      dataType: 'input',
      isStatic: true,
      isInternal: true,
    },
    {
      name: 'escalation_at',
      display: __('Escalation at'),
      dataType: 'datetime',
      isStatic: true,
      isInternal: true,
    },
    {
      name: 'first_response_escalation_at',
      display: __('Escalation at (First Response Time)'),
      dataType: 'datetime',
      isStatic: true,
      isInternal: true,
    },
    {
      name: 'update_escalation_at',
      display: __('Escalation at (Update Time)'),
      dataType: 'datetime',
      isStatic: true,
      isInternal: true,
    },
    {
      name: 'close_escalation_at',
      display: __('Escalation at (Close Time)'),
      dataType: 'datetime',
      isStatic: true,
      isInternal: true,
    },
    {
      name: 'last_contact_at',
      display: __('Last contact'),
      dataType: 'datetime',
      isStatic: true,
      isInternal: true,
    },
    {
      name: 'last_contact_agent_at',
      display: __('Last contact (agent)'),
      dataType: 'datetime',
      isStatic: true,
      isInternal: true,
    },
    {
      name: 'last_contact_customer_at',
      display: __('Last contact (customer)'),
      dataType: 'datetime',
      isStatic: true,
      isInternal: true,
    },
    {
      name: 'first_response_at',
      display: __('First response'),
      dataType: 'datetime',
      isStatic: true,
      isInternal: true,
    },
    {
      name: 'close_at',
      display: __('Closing time'),
      dataType: 'datetime',
      isStatic: true,
      isInternal: true,
    },
    {
      name: 'last_close_at',
      display: __('Last closing time'),
      dataType: 'datetime',
      isStatic: true,
      isInternal: true,
    },
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
    {
      name: 'last_owner_update_at',
      display: __('Last owner update'),
      dataType: 'datetime',
      isStatic: true,
      isInternal: true,
    },
  ],
}
