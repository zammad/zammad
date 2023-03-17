// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import {
  convertToGraphQLId,
  isGraphQLId,
  ensureGraphqlId,
  parseGraphqlId,
  getIdFromGraphQLId,
} from '../utils'

describe('isGraphQLId', () => {
  it('check for valid id', async () => {
    expect(isGraphQLId('gid://zammad/Organization/1')).toBe(true)
  })

  it('check for invalid id', async () => {
    expect(isGraphQLId('invalid')).toBe(false)
  })
})

describe('convertToGraphQLId', () => {
  it('check convertion', async () => {
    expect(convertToGraphQLId('Organization', 1)).toBe(
      'gid://zammad/Organization/1',
    )
  })
})

describe('convertToGraphQLId', () => {
  it('check convertion', async () => {
    expect(convertToGraphQLId('Organization', 1)).toBe(
      'gid://zammad/Organization/1',
    )
  })
})

describe('ensureGraphqlId', () => {
  it('check that we have always a GraphQL id', async () => {
    expect(ensureGraphqlId('Organization', 1)).toBe(
      'gid://zammad/Organization/1',
    )
  })

  it('check that we have always a GraphQL id (also when it has the correct format)', async () => {
    expect(ensureGraphqlId('Organization', 'gid://zammad/Organization/1')).toBe(
      'gid://zammad/Organization/1',
    )
  })
})

describe('getIdFromGraphQLId', () => {
  it('check that ID can parsed from graphqlId ', async () => {
    expect(getIdFromGraphQLId('gid://zammad/Organization/1')).toBe(1)
  })
})

describe('parseGraphqlId', () => {
  it('correctly parses graphqlId ', async () => {
    expect(parseGraphqlId('gid://zammad/Organization/1')).toEqual({
      relation: 'Organization',
      id: 1,
    })
  })
})
