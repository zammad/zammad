// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { defaultOrganization } from '@mobile/entities/organization/__tests__/mocks/organization-mocks'
import { ObjectManagerFrontendAttributesDocument } from '@shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.api'
import { UserUpdatesDocument } from '@shared/graphql/subscriptions/userUpdates.api'
import type { UserQuery } from '@shared/graphql/types'
import type { ConfidentTake } from '@shared/types/utils'
import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '@tests/support/mock-graphql-api'
import { nullableMock } from '@tests/support/utils'
import { UserDocument } from '../../graphql/queries/user.api'
import managerAttributes from './managerAttributes.json'

export const defaultUser = (): ConfidentTake<UserQuery, 'user'> => {
  const organization = defaultOrganization()

  const user = nullableMock<ConfidentTake<UserQuery, 'user'>>({
    __typename: 'User',
    id: 'dsad34dasd21',
    internalId: 200,
    firstname: 'John',
    lastname: 'Doe',
    fullname: 'John Doe',
    ticketsCount: {
      open: 4,
      closed: 2,
    },
    organization: {
      __typename: 'Organization',
      id: organization.id,
      internalId: organization.internalId,
      name: organization.name,
      ticketsCount: organization.ticketsCount,
    },
    secondaryOrganizations: {
      __typename: 'OrganizationConnection',
      edges: [
        {
          __typename: 'OrganizationEdge',
          node: {
            __typename: 'Organization',
            id: 'dsa34fsa223d',
            name: 'Dammaz',
            internalId: 10,
            active: true,
          },
        },
      ],
      totalCount: 1,
    },
    objectAttributeValues: [
      {
        attribute: {
          name: 'department',
          display: 'Department',
          dataType: 'input',
          dataOption: {
            type: 'text',
            maxlength: 200,
            null: true,
            item_class: 'formGroup--halfSize',
          },
          __typename: 'ObjectManagerFrontendAttribute',
        },
        value: '',
        __typename: 'ObjectAttributeValue',
      },
      {
        attribute: {
          name: 'address',
          display: 'Address',
          dataType: 'textarea',
          dataOption: {
            type: 'text',
            maxlength: 500,
            rows: 4,
            null: true,
            item_class: 'formGroup--halfSize',
          },
          __typename: 'ObjectManagerFrontendAttribute',
        },
        value: '',
        __typename: 'ObjectAttributeValue',
      },
    ],
  })

  return user
}

export const mockUserManagerAttributes = () => {
  return mockGraphQLApi(ObjectManagerFrontendAttributesDocument).willResolve({
    objectManagerFrontendAttributes: managerAttributes,
  })
}

export const mockUserDetailsApis = (
  user?: ConfidentTake<UserQuery, 'user'>,
) => {
  const mockedUser = user ?? defaultUser()

  const mockUser = mockGraphQLApi(UserDocument).willResolve({
    user: mockedUser,
  })
  const mockAttributes = mockUserManagerAttributes()
  const mockUserSubscription = mockGraphQLSubscription(UserUpdatesDocument)

  return {
    user: mockedUser,
    mockUser,
    mockAttributes,
    mockUserSubscription,
  }
}
