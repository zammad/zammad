// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectManagerFrontendAttributesPayload } from '#shared/graphql/types.ts'

export default (): ObjectManagerFrontendAttributesPayload => ({
  attributes: [
    {
      name: 'title',
      display: 'Title',
      dataType: 'input',
      dataOption: {
        type: 'text',
        maxlength: 200,
        null: false,
        translate: false,
      },
      isInternal: true,
      screens: {
        create_top: {
          null: false,
        },
        edit: {},
      },
      __typename: 'ObjectManagerFrontendAttribute',
    },
    {
      name: 'customer_id',
      display: 'Customer',
      dataType: 'user_autocompletion',
      dataOption: {
        relation: 'User',
        autocapitalize: false,
        multiple: false,
        guess: true,
        null: false,
        limit: 200,
        placeholder: 'Enter Person or Organization/Company',
        minLengt: 2,
        translate: false,
        permission: ['ticket.agent'],
        belongs_to: 'customer',
      },
      isInternal: true,
      screens: {
        create_top: {
          null: false,
        },
        edit: {},
      },
      __typename: 'ObjectManagerFrontendAttribute',
    },
    {
      name: 'organization_id',
      display: 'Organization',
      dataType: 'autocompletion_ajax_customer_organization',
      dataOption: {
        relation: 'Organization',
        autocapitalize: false,
        multiple: false,
        null: true,
        translate: false,
        permission: ['ticket.agent', 'ticket.customer'],
        belongs_to: 'organization',
      },
      isInternal: true,
      screens: {
        create_top: {
          null: false,
        },
        edit: {},
      },
      __typename: 'ObjectManagerFrontendAttribute',
    },
    {
      name: 'group_id',
      display: 'Group',
      dataType: 'select',
      dataOption: {
        default: '',
        relation: 'Group',
        relation_condition: {
          access: 'full',
        },
        nulloption: true,
        multiple: false,
        null: false,
        translate: false,
        only_shown_if_selectable: true,
        permission: ['ticket.agent', 'ticket.customer'],
        maxlength: 255,
        belongs_to: 'group',
      },
      isInternal: true,
      screens: {
        create_middle: {
          null: false,
          item_class: 'column',
        },
        edit: {
          null: false,
        },
        overview_bulk: {
          null: true,
        },
      },
      __typename: 'ObjectManagerFrontendAttribute',
    },
    {
      name: 'owner_id',
      display: 'Owner',
      dataType: 'select',
      dataOption: {
        default: '',
        relation: 'User',
        relation_condition: {
          roles: 'Agent',
        },
        nulloption: true,
        multiple: false,
        null: true,
        translate: false,
        permission: ['ticket.agent'],
        maxlength: 255,
        belongs_to: 'owner',
      },
      isInternal: true,
      screens: {
        create_middle: {
          null: true,
          item_class: 'column',
        },
        edit: {
          null: true,
        },
        overview_bulk: {
          null: true,
        },
      },
      __typename: 'ObjectManagerFrontendAttribute',
    },
    {
      name: 'state_id',
      display: 'State',
      dataType: 'select',
      dataOption: {
        relation: 'TicketState',
        nulloption: true,
        multiple: false,
        null: false,
        default: 2,
        translate: true,
        filter: [2, 1, 3, 4, 6, 7],
        maxlength: 255,
        belongs_to: 'state',
      },
      isInternal: true,
      screens: {
        create_middle: {
          null: false,
          item_class: 'column',
          filter: [2, 1, 3, 4, 7],
        },
        edit: {
          nulloption: false,
          null: false,
          filter: [2, 3, 4, 7],
        },
        overview_bulk: {
          null: true,
        },
      },
      __typename: 'ObjectManagerFrontendAttribute',
    },
    {
      name: 'pending_time',
      display: 'Pending till',
      dataType: 'datetime',
      dataOption: {
        future: true,
        past: false,
        diff: null,
        null: true,
        translate: true,
        permission: ['ticket.agent'],
      },
      isInternal: true,
      screens: {
        create_middle: {
          null: false,
          item_class: 'column',
        },
        edit: {
          null: false,
        },
        overview_bulk: {
          null: true,
        },
      },
      __typename: 'ObjectManagerFrontendAttribute',
    },
    {
      name: 'priority_id',
      display: 'Priority',
      dataType: 'select',
      dataOption: {
        relation: 'TicketPriority',
        nulloption: false,
        multiple: false,
        null: false,
        default: 2,
        translate: true,
        maxlength: 255,
        belongs_to: 'priority',
      },
      isInternal: true,
      screens: {
        create_middle: {
          null: false,
          item_class: 'column',
        },
        edit: {
          null: false,
        },
        overview_bulk: {
          null: true,
        },
      },
      __typename: 'ObjectManagerFrontendAttribute',
    },
    {
      name: 'tags',
      display: 'Tags',
      dataType: 'tag',
      dataOption: {
        type: 'text',
        null: true,
        translate: false,
      },
      isInternal: true,
      screens: {
        create_bottom: {
          null: true,
        },
        edit: {},
      },
      __typename: 'ObjectManagerFrontendAttribute',
    },
  ],
  screens: [
    {
      name: 'create_top',
      attributes: ['title', 'customer_id', 'organization_id'],
      __typename: 'ObjectManagerScreenAttributes',
    },
    {
      name: 'edit',
      attributes: [
        'group_id',
        'owner_id',
        'state_id',
        'pending_time',
        'priority_id',
      ],
      __typename: 'ObjectManagerScreenAttributes',
    },
    {
      name: 'create_middle',
      attributes: [
        'group_id',
        'owner_id',
        'state_id',
        'pending_time',
        'priority_id',
      ],
      __typename: 'ObjectManagerScreenAttributes',
    },
    {
      name: 'create_bottom',
      attributes: ['tags'],
      __typename: 'ObjectManagerScreenAttributes',
    },
  ],
  __typename: 'ObjectManagerFrontendAttributesPayload',
})
