// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '#tests/support/mock-graphql-api.ts'
import type { MockGraphQLInstance } from '#tests/support/mock-graphql-api.ts'
import { nullableMock, waitUntil } from '#tests/support/utils.ts'

import { mockOnlineNotificationSeenGql } from '#shared/composables/__tests__/mocks/online-notification.ts'
import { ObjectManagerFrontendAttributesDocument } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.api.ts'
import { UserDocument } from '#shared/entities/user/graphql/queries/user.api.ts'
import { UserUpdatesDocument } from '#shared/graphql/subscriptions/userUpdates.api.ts'
import type { UserQuery } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'

import { defaultOrganization } from '#mobile/entities/organization/__tests__/mocks/organization-mocks.ts'

import managerAttributes from './managerAttributes.json'

export const userObjectAttributes = () => ({ ...managerAttributes })

export const defaultUser = (): ConfidentTake<UserQuery, 'user'> => {
  const organization = defaultOrganization()

  const user = nullableMock<ConfidentTake<UserQuery, 'user'>>({
    __typename: 'User',
    id: convertToGraphQLId('User', 100),
    internalId: 100,
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

interface MockOptions {
  skipMockOnlineNotificationSeen?: boolean
}

export const mockUserDetailsApis = (
  user?: ConfidentTake<UserQuery, 'user'>,
  options: MockOptions = {},
) => {
  const mockedUser = user ?? defaultUser()

  const { mockUser } = mockUserGql(user)
  const mockAttributes = mockUserManagerAttributes()
  const mockUserSubscription = mockGraphQLSubscription(UserUpdatesDocument)

  let mockOnlineNotificationSeen: MockGraphQLInstance | undefined
  if (!options.skipMockOnlineNotificationSeen) {
    mockOnlineNotificationSeen = mockOnlineNotificationSeenGql()
  }

  return {
    user: mockedUser,
    mockUser,
    mockAttributes,
    mockUserSubscription,
    mockOnlineNotificationSeen,
  }
}
