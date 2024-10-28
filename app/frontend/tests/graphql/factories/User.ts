// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { faker } from '@faker-js/faker'

import type { Organization, User } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

import { getStoredMockedObject } from '../builders/index.ts'

export default (
  parent: any | undefined,
  userValue: User | undefined,
): DeepPartial<User> => {
  const firstname = faker.person.firstName()
  const lastname = faker.person.lastName()
  const user: DeepPartial<User> = {
    firstname,
    lastname,
    fullname: `${firstname} ${lastname}`,
    image: faker.image.dataUri(),
    imageSource: null,
    email: faker.internet.email(),
    fax: null,
    login: faker.internet.username(),
    phone: '+49 #### ######'.replace(/#+/g, (m) =>
      faker.string.numeric(m.length),
    ),
    outOfOffice: null,
    outOfOfficeStartAt: null,
    outOfOfficeEndAt: null,
    outOfOfficeReplacement: null,
    objectAttributeValues: [],
    createdBy: null,
    secondaryOrganizations: {
      edges: [],
      totalCount: 0,
    },
    updatedBy: null,
    policy: {
      update: true,
      destroy: true,
    },
    authorizations: [],
  }
  if (parent?.__typename === 'Organization') {
    user.organization = parent
  } else if (userValue) {
    const organization = getStoredMockedObject<Organization>('Organization', 1)
    if (organization) {
      // if the organization already exists, add the user to it
      user.organization = organization
      const members = organization.allMembers.edges
      const lastCursor = members[members.length - 1]?.cursor
      const cursor = `${lastCursor || 'AB'}A`
      organization.allMembers.edges.push({
        __typename: 'UserEdge',
        cursor,
        node: userValue as any,
      })
      organization.allMembers.totalCount += 1
      organization.allMembers.pageInfo ??= {} as any
      organization.allMembers.pageInfo.startCursor =
        members[0]?.cursor || cursor
      organization.allMembers.pageInfo.endCursor = cursor
    } else {
      user.organization = {
        id: convertToGraphQLId('Organization', 1),
      }
    }
  }
  return user
}
