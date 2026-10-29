// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { isSystemUser, isSystemUserId } from '../isSystemUser.ts'

describe('isSystemUser', () => {
  it('recognises the system account by its id', () => {
    expect(isSystemUser({ id: convertToGraphQLId('User', 1) })).toBe(true)
    expect(isSystemUser({ id: convertToGraphQLId('User', 2) })).toBe(false)
  })

  it('treats a missing user as no system account', () => {
    expect(isSystemUser(null)).toBe(false)
    expect(isSystemUser(undefined)).toBe(false)
  })
})

describe('isSystemUserId', () => {
  it('recognises the id of the system account', () => {
    expect(isSystemUserId(convertToGraphQLId('User', 1))).toBe(true)
    expect(isSystemUserId(convertToGraphQLId('User', 2))).toBe(false)
    expect(isSystemUserId(undefined)).toBe(false)
  })
})
