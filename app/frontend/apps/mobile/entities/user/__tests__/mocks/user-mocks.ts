// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { defaultOrganization } from '@mobile/entities/organization/__tests__/mocks/organization-mocks'
import { ObjectManagerFrontendAttributesDocument } from '@shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.api'
import { UserUpdatesDocument } from '@shared/graphql/subscriptions/userUpdates.api'
import type { UserQuery } from '@shared/graphql/types'
import { convertToGraphQLId } from '@shared/graphql/utils'
import type { ConfidentTake } from '@shared/types/utils'
import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '@tests/support/mock-graphql-api'
import { nullableMock, waitUntil } from '@tests/support/utils'
import { UserDocument } from '../../graphql/queries/user.api'
import managerAttributes from './managerAttributes.json'

export const userObjectAttributes = () => ({ ...managerAttributes })

export const defaultUser = (): ConfidentTake<UserQuery, 'user'> => {
  const organization = defaultOrganization()

  const user = nullableMock<ConfidentTake<UserQuery, 'user'>>({
    __typename: 'User',
    id: convertToGraphQLId('User', 1),
    internalId: 1,
    firstname: 'John',
    lastname: 'Doe',
    fullname: 'John Doe',
    active: true,
    vip: false,
    image: null,
    ticketsCount: {
      open: 4,
      closed: 2,
    },
    policy: {
      update: true,
    },
    organization: {
      __typename: 'Organization',
      id: organization.id,
      internalId: organization.internalId,
      name: organization.name,
      ticketsCount: organization.ticketsCount,
      active: true,
    },
    secondaryOrganizations: {
      __typename: 'OrganizationConnection',
      edges: [
        {
          __typename: 'OrganizationEdge',
          node: {
            __typename: 'Organization',
            id: convertToGraphQLId('Organization', 10),
            name: 'Dammaz',
            internalId: 10,
            active: true,
          },
        },
      ],
      totalCount: 1,
    },
    hasSecondaryOrganizations: true,
    objectAttributeValues: [
      {
        attribute: {
          name: 'department',
          display: 'Department',
          __typename: 'ObjectManagerFrontendAttribute',
        },
        value: '',
        renderedLink: null,
        __typename: 'ObjectAttributeValue',
      },
      {
        attribute: {
          name: 'address',
          display: 'Address',
          __typename: 'ObjectManagerFrontendAttribute',
        },
        value: '',
        renderedLink: null,
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

export const mockUserGql = (user?: ConfidentTake<UserQuery, 'user'>) => {
  const mockedUser = user ?? defaultUser()

  const mockUser = mockGraphQLApi(UserDocument).willResolve({
    user: mockedUser,
  })

  const waitUntillUserLoaded = () => waitUntil(() => mockUser.spies.resolve)

  return {
    mockUser,
    waitUntillUserLoaded,
  }
}

export const mockUserDetailsApis = (
  user?: ConfidentTake<UserQuery, 'user'>,
) => {
  const mockedUser = user ?? defaultUser()

  const { mockUser } = mockUserGql(user)
  const mockAttributes = mockUserManagerAttributes()
  const mockUserSubscription = mockGraphQLSubscription(UserUpdatesDocument)

  return {
    user: mockedUser,
    mockUser,
    mockAttributes,
    mockUserSubscription,
  }
}
