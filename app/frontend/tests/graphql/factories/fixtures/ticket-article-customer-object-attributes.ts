// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectManagerFrontendAttributesPayload } from '#shared/graphql/types.ts'

export default (): ObjectManagerFrontendAttributesPayload => ({
  attributes: [
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
      attributes: ['body'],
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
