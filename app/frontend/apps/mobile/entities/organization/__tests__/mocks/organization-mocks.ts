// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mockGraphQLApi } from '#tests/support/mock-graphql-api.ts'
import { nullableMock } from '#tests/support/utils.ts'

import { ObjectManagerFrontendAttributesDocument } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.api.ts'
import type {
  ObjectManagerFrontendAttributesPayload,
  OrganizationQuery,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'

export const defaultOrganization = (): ConfidentTake<
  OrganizationQuery,
  'organization'
> =>
  nullableMock({
    __typename: 'Organization',
    id: convertToGraphQLId('Organization', 100),
    internalId: 100,
    name: 'Some Organization',
    shared: false,
    domain: 'some-domain@domain.me',
    domainAssignment: true,
    active: true,
    vip: false,
    note: 'Save something as this note',
    objectAttributeValues: [],
    policy: {
      update: true,
    },
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
            id: convertToGraphQLId('User', 2),
            internalId: 1,
            vip: false,
            firstname: 'John',
            lastname: 'Doe',
            fullname: 'John Doe',
            image: null,
            outOfOffice: false,
            active: true,
          },
        },
      ],
      totalCount: 1,
    },
  })

export const organizationObjectAttributes =
  (): ObjectManagerFrontendAttributesPayload => ({
    attributes: [
      {
        __typename: 'ObjectManagerFrontendAttribute',
        name: 'name',
        display: 'Name',
        dataType: 'input',
        dataOption: {
          type: 'text',
          maxlength: 150,
          null: false,
          item_class: 'formGroup--halfSize',
        },
        screens: {},
        isInternal: true,
      },
      {
        __typename: 'ObjectManagerFrontendAttribute',
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
        screens: {},
        isInternal: true,
      },
      {
        __typename: 'ObjectManagerFrontendAttribute',
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
        screens: {},
        isInternal: true,
      },
      {
        __typename: 'ObjectManagerFrontendAttribute',
        name: 'domain',
        display: 'Domain',
        dataType: 'input',
        dataOption: {
          type: 'text',
          maxlength: 150,
          null: true,
          item_class: 'formGroup--halfSize',
        },
        screens: {},
        isInternal: true,
      },
      {
        __typename: 'ObjectManagerFrontendAttribute',
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
        screens: {},
        isInternal: true,
      },
      {
        __typename: 'ObjectManagerFrontendAttribute',
        name: 'active',
        display: 'Active',
        dataType: 'active',
        dataOption: {
          null: true,
          default: true,
          permission: ['admin.organization'],
        },
        screens: {},
        isInternal: true,
      },
      {
        __typename: 'ObjectManagerFrontendAttribute',
        name: 'vip',
        display: 'VIP',
        dataType: 'boolean',
        dataOption: {
          options: {
            true: 'yes',
            false: 'no',
          },
          null: true,
          default: false,
          permission: ['admin.organization'],
        },
        screens: {},
        isInternal: true,
      },
      {
        __typename: 'ObjectManagerFrontendAttribute',
        name: 'test',
        display: 'Test Field',
        dataType: 'input',
        dataOption: {
          default: '',
          type: 'text',
          maxlength: 120,
          linktemplate: '',
          null: true,
          options: {},
          relation: '',
        },
        screens: {},
        isInternal: false,
      },
      {
        __typename: 'ObjectManagerFrontendAttribute',
        name: 'textarea',
        display: 'Textarea Field',
        dataType: 'textarea',
        dataOption: {
          default: '',
          maxlength: 500,
          rows: 4,
          null: true,
          options: {},
          relation: '',
        },
        screens: {},
        isInternal: false,
      },
    ],
    screens: [
      {
        name: 'view',
        attributes: [
          'name',
          'shared',
          'domain_assignment',
          'domain',
          'note',
          'active',
          'vip',
          'test',
          'textarea',
        ],
      },
      {
        name: 'edit',
        attributes: [
          'name',
          'shared',
          'domain_assignment',
          'domain',
          'note',
          'active',
          'vip',
          'test',
          'textarea',
        ],
      },
    ],
  })

export const mockOrganizationObjectAttributes = (
  attributes?: ObjectManagerFrontendAttributesPayload,
) => {
  return mockGraphQLApi(ObjectManagerFrontendAttributesDocument).willResolve({
    objectManagerFrontendAttributes:
      attributes || organizationObjectAttributes(),
  })
}
