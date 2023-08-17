// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { faker } from '@faker-js/faker'
import type { Organization } from '#shared/graphql/types.ts'
import type { DeepPartial } from '#shared/types/utils.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

export default (parent: any): DeepPartial<Organization> => {
  const organization: DeepPartial<Organization> = {
    id: convertToGraphQLId('Organization', 1),
    domain: faker.internet.domainName(),
    objectAttributeValues: [],
  }
  // to not go into an infine loop
  if (parent?.__typename === 'User') {
    organization.members = {
      edges: [{ __typename: 'UserEdge', node: parent, cursor: 'AB' }],
      pageInfo: {
        endCursor: 'AB',
        startCursor: 'AB',
        hasNextPage: false,
        hasPreviousPage: false,
      },
      totalCount: 1,
    }
  } else {
    organization.members = {
      edges: [],
      totalCount: 0,
    }
  }
  return organization
}
