// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectManagerFrontendAttributesPayload } from '#shared/graphql/types.ts'

export default (): ObjectManagerFrontendAttributesPayload => ({
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
