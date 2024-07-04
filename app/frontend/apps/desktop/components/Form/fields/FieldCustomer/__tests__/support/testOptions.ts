// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { nullableMock } from '#tests/support/utils.ts'

import type { AutocompleteSearchGenericEntry } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

export const testOptions: AutocompleteSearchGenericEntry[] = [
  {
    __typename: 'AutocompleteSearchGenericEntry',
    value: 2,
    label: 'Nicole Braun',
    labelPlaceholder: [],
    heading: 'Zammad Foundation',
    headingPlaceholder: [],
    disabled: false,
    icon: null,
    object: nullableMock({
      __typename: 'User',
      id: convertToGraphQLId('User', 2),
      internalId: 2,
      login: 'nicole.braun@zammad.org',
      firstname: 'Nicole',
      lastname: 'Braun',
      fullname: 'Nicole Braun',
      email: 'nicole.braun@zammad.org',
      image: null,
      phone: null,
      outOfOffice: null,
      outOfOfficeStartAt: null,
      outOfOfficeEndAt: null,
      active: true,
      vip: false,
      createdAt: '2022-11-30T12:40:15Z',
      updatedAt: '2022-11-30T12:40:15Z',
      policy: {
        update: true,
        destroy: false,
      },
      organization: null,
      hasSecondaryOrganizations: false,
    }),
  },
  {
    __typename: 'AutocompleteSearchGenericEntry',
    value: 1,
    label: 'Zammad Foundation',
    labelPlaceholder: [],
    heading: '%s people',
    headingPlaceholder: ['1'],
    disabled: true,
    icon: null,
    object: nullableMock({
      __typename: 'Organization',
      id: convertToGraphQLId('Organization', 1),
      internalId: 1,
      name: 'Zammad Foundation',
      active: true,
      vip: false,
      allMembers: {
        edges: [
          {
            __typename: 'UserEdge',
            node: nullableMock({
              __typename: 'User',
              id: convertToGraphQLId('User', 1),
              internalId: 1,
              login: 'nicole.braun@zammad.org',
              firstname: 'Nicole',
              lastname: 'Braun',
              fullname: 'Nicole Braun',
              email: 'nicole.braun@zammad.org',
              image: null,
              phone: null,
              outOfOffice: null,
              outOfOfficeStartAt: null,
              outOfOfficeEndAt: null,
              active: true,
              vip: false,
              createdAt: '2022-11-30T12:40:15Z',
              updatedAt: '2022-11-30T12:40:15Z',
              policy: {
                update: true,
                destroy: false,
              },
            }),
            cursor: 'MH',
          },
        ],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: 'MH',
        },
        totalCount: 1,
      },
      createdAt: '2022-11-30T12:40:15Z',
      updatedAt: '2022-11-30T12:40:15Z',
      policy: {
        update: true,
        destroy: false,
      },
    }),
  },
]
