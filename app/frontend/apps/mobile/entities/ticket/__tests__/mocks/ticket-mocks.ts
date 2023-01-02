// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { ObjectManagerFrontendAttributesDocument } from '@shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.api'
import type { ObjectManagerFrontendAttributesPayload } from '@shared/graphql/types'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { nullableMock } from '@tests/support/utils'

export const ticketObjectAttributes = () => ({
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

export const ticketArticleObjectAttributes = () => ({
  attributes: [
    {
      name: 'type_id',
      display: 'Type',
      dataType: 'select',
      dataOption: {
        relation: 'TicketArticleType',
        nulloption: false,
        multiple: false,
        null: false,
        default: 10,
        translate: true,
        maxlength: 255,
        belongs_to: 'type',
      },
      isInternal: true,
      screens: {
        create_middle: {},
        edit: {
          null: false,
        },
      },
      __typename: 'ObjectManagerFrontendAttribute',
    },
    {
      name: 'internal',
      display: 'Visibility',
      dataType: 'select',
      dataOption: {
        options: {
          true: 'internal',
          false: 'public',
        },
        nulloption: false,
        multiple: false,
        null: true,
        default: false,
        translate: true,
        maxlength: 255,
      },
      isInternal: true,
      screens: {
        create_middle: {},
        edit: {
          null: false,
        },
      },
      __typename: 'ObjectManagerFrontendAttribute',
    },
    {
      name: 'to',
      display: 'To',
      dataType: 'input',
      dataOption: {
        type: 'text',
        maxlength: 1000,
        null: true,
      },
      isInternal: true,
      screens: {
        create_middle: {},
        edit: {
          null: true,
        },
      },
      __typename: 'ObjectManagerFrontendAttribute',
    },
    {
      name: 'cc',
      display: 'CC',
      dataType: 'input',
      dataOption: {
        type: 'text',
        maxlength: 1000,
        null: true,
      },
      isInternal: true,
      screens: {
        create_top: {},
        create_middle: {},
        edit: {
          null: true,
        },
      },
      __typename: 'ObjectManagerFrontendAttribute',
    },
    {
      name: 'body',
      display: 'Text',
      dataType: 'richtext',
      dataOption: {
        type: 'richtext',
        maxlength: 150000,
        upload: true,
        rows: 8,
        null: true,
      },
      isInternal: true,
      screens: {
        create_top: {
          null: false,
        },
        edit: {
          null: true,
        },
      },
      __typename: 'ObjectManagerFrontendAttribute',
    },
  ],
  screens: [
    {
      name: 'create_middle',
      attributes: [],
      __typename: 'ObjectManagerScreenAttributes',
    },
    {
      name: 'edit',
      attributes: ['type_id', 'internal', 'to', 'cc', 'body'],
      __typename: 'ObjectManagerScreenAttributes',
    },
    {
      name: 'create_top',
      attributes: ['body'],
      __typename: 'ObjectManagerScreenAttributes',
    },
  ],
  __typename: 'ObjectManagerFrontendAttributesPayload',
})

export const mockTicketObjectAttributesGql = (
  attributes?: ObjectManagerFrontendAttributesPayload,
) => {
  return mockGraphQLApi(ObjectManagerFrontendAttributesDocument).willResolve({
    objectManagerFrontendAttributes: attributes || ticketObjectAttributes(),
  })
}

export const ticketPayload = (id = 1) =>
  nullableMock({
    id: `gid://zammad/Ticket/${id}`,
    internalId: id,
    number: 7800 + id,
    title: 'Ticket Title',
    createdAt: '2022-11-30T12:40:15Z',
    updatedAt: '2022-11-30T12:40:15Z',
    pendingTime: null,
    owner: {
      id: 'gid://zammad/User/1',
      internalId: 1,
      firstname: '-',
      lastname: '',
      __typename: 'User',
    },
    customer: {
      id: 'gid://zammad/User/2',
      internalId: 2,
      firstname: 'Nicole',
      lastname: 'Braun',
      fullname: 'Nicole Braun',
      __typename: 'User',
    },
    organization: {
      id: 'gid://zammad/Organization/1',
      internalId: 1,
      name: 'Zammad Foundation',
      __typename: 'Organization',
    },
    state: {
      id: 'gid://zammad/Ticket::State/2',
      name: 'open',
      stateType: {
        name: 'open',
        __typename: 'TicketStateType',
      },
      __typename: 'TicketState',
    },
    group: {
      id: 'gid://zammad/Group/1',
      name: 'Users',
      __typename: 'Group',
    },
    priority: {
      id: 'gid://zammad/Ticket::Priority/2',
      name: '2 normal',
      defaultCreate: true,
      uiColor: null,
      __typename: 'TicketPriority',
    },
    objectAttributeValues: [],
    tags: null,
    subscribed: false,
    __typename: 'Ticket',
  })
