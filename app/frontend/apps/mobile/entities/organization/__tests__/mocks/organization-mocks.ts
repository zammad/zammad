// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { ObjectManagerFrontendAttributesDocument } from '@shared/graphql/queries/objectManagerFrontendAttributes.api'
import type { OrganizationQuery } from '@shared/graphql/types'
import type { ConfidentTake } from '@shared/types/utils'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { nullableMock } from '@tests/support/utils'

export const defaultOrganization = (): ConfidentTake<
  OrganizationQuery,
  'organization'
> =>
  nullableMock({
    __typename: 'Organization',
    id: '3423225dsf0',
    name: 'Some Organization',
    shared: false,
    domain: 'some-domain@domain.me',
    domainAssignment: true,
    active: true,
    note: 'Save something as this note',
    objectAttributeValues: [],
    ticketsCount: {
      open: 3,
      closed: 1,
    },
    members: {
      __typename: 'UserConnection',
      edges: [
        {
          __typename: 'UserEdge',
          node: {
            __typename: 'User',
            id: 'fds2342das23ds21sa',
            internalId: 1,
            firstname: 'John',
            lastname: 'Doe',
            fullname: 'John Doe',
            image: null,
          },
        },
      ],
      totalCount: 1,
    },
  })

export const organizationObjectAttributes = () => [
  {
    name: 'name',
    display: 'Name',
    dataType: 'input',
    dataOption: {
      type: 'text',
      maxlength: 150,
      null: false,
      item_class: 'formGroup--halfSize',
    },
    __typename: 'ObjectManagerFrontendAttribute',
  },
  {
    name: 'shared',
    display: 'Shared organization',
    dataType: 'boolean',
    dataOption: {
      null: true,
      default: true,
      note: "Customers in the organization can view each other's items.",
      item_class: 'formGroup--halfSize',
      options: {
        true: 'yes',
        false: 'no',
      },
      translate: true,
      permission: ['admin.organization'],
    },
    __typename: 'ObjectManagerFrontendAttribute',
  },
  {
    name: 'domain_assignment',
    display: 'Domain based assignment',
    dataType: 'boolean',
    dataOption: {
      null: true,
      default: false,
      note: 'Assign users based on user domain.',
      item_class: 'formGroup--halfSize',
      options: {
        true: 'yes',
        false: 'no',
      },
      translate: true,
      permission: ['admin.organization'],
    },
    __typename: 'ObjectManagerFrontendAttribute',
  },
  {
    name: 'domain',
    display: 'Domain',
    dataType: 'input',
    dataOption: {
      type: 'text',
      maxlength: 150,
      null: true,
      item_class: 'formGroup--halfSize',
    },
    __typename: 'ObjectManagerFrontendAttribute',
  },
  {
    name: 'note',
    display: 'Note',
    dataType: 'richtext',
    dataOption: {
      type: 'text',
      maxlength: 5000,
      null: true,
      note: 'Notes are visible to agents only, never to customers.',
      no_images: true,
    },
    __typename: 'ObjectManagerFrontendAttribute',
  },
  {
    name: 'active',
    display: 'Active',
    dataType: 'active',
    dataOption: {
      null: true,
      default: true,
      permission: ['admin.organization'],
    },
    __typename: 'ObjectManagerFrontendAttribute',
  },
]

export const mockOrganizationObjectAttributes = () => {
  return mockGraphQLApi(ObjectManagerFrontendAttributesDocument).willResolve({
    objectManagerFrontendAttributes: organizationObjectAttributes(),
  })
}
