// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

export const userOption = [
  {
    __typename: 'User',
    id: convertToGraphQLId('User', 2),
    internalId: 2,
    image: null,
    firstname: 'Nicole',
    lastname: 'Braun',
    fullname: 'Nicole Braun',
    outOfOffice: false,
    outOfOfficeStartAt: null,
    outOfOfficeEndAt: null,
    active: true,
    vip: false,
  },
  {
    __typename: 'User',
    id: convertToGraphQLId('User', 4),
    internalId: 4,
    image: null,
    firstname: 'Agent 1',
    lastname: 'Test',
    fullname: 'Agent 1 Test',
    outOfOffice: false,
    outOfOfficeStartAt: null,
    outOfOfficeEndAt: null,
    active: true,
    vip: false,
  },
  {
    __typename: 'User',
    id: convertToGraphQLId('User', 8),
    internalId: 8,
    image: null,
    firstname: 'Thomas',
    lastname: 'Ernst',
    fullname: 'Thomas Ernst',
    outOfOffice: false,
    outOfOfficeStartAt: null,
    outOfOfficeEndAt: null,
    active: true,
    vip: false,
  },
]

export const organizationOption = [
  {
    __typename: 'Organization',
    id: convertToGraphQLId('Organization', 2),
    internalId: 2,
    active: true,
    name: 'Spar',
  },
  {
    __typename: 'Organization',
    id: convertToGraphQLId('Organization', 3),
    internalId: 3,
    active: true,
    name: 'Billa',
  },
  {
    __typename: 'Organization',
    id: convertToGraphQLId('Organization', 4),
    internalId: 4,
    active: true,
    name: 'Mercadona',
  },
]
