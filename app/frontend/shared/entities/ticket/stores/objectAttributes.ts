// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type {
  EntityPolicyBasedObjectAttributeScreenMapper,
  EntityStaticObjectAttributes,
} from '#shared/entities/object-attributes/types/store.ts'
import { EnumObjectManagerObjects, type PolicyTicket } from '#shared/graphql/types.ts'

export const staticObjectAttributes: EntityStaticObjectAttributes = {
  name: EnumObjectManagerObjects.Ticket,
  attributes: [
    {
      name: 'time_unit',
      display: __('Accounted time'),
      dataType: 'integer', // :TODO in the desktop app it is float
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
      display: __('Escalation at (First response time)'),
      dataType: 'datetime',
      isStatic: true,
      isInternal: true,
    },
    {
      name: 'update_escalation_at',
      display: __('Escalation at (Update time)'),
      dataType: 'datetime',
      isStatic: true,
      isInternal: true,
    },
    {
      name: 'close_escalation_at',
      display: __('Escalation at (Close time)'),
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
        belongs_to: 'createdBy',
      },
      dataType: 'autocompletion_ajax',
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
        belongs_to: 'updatedBy',
      },
      dataType: 'autocompletion_ajax',
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

export const policyBasedObjectAttributeScreenMapper: EntityPolicyBasedObjectAttributeScreenMapper<PolicyTicket> =
  {
    name: EnumObjectManagerObjects.Ticket,
    mappings: {
      edit: (policy: PolicyTicket) => {
        // edit_customer screen is used by Agent-Customers in tickets they have customer access to.
        // Regular customers still use the edit screen.
        // It is not possible to detect Agent-Customer or regular customer here.
        // This function returns edit_customer for anybody who has no agent access to the given ticket.
        // Then resolveScreenName() at useObjectAttributeFormFields.ts will figure out the final screen name.
        return policy.agentReadAccess ? 'edit' : 'edit_customer'
      },
    },
  }
