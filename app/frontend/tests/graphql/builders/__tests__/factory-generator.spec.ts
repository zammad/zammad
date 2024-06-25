// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { faker } from '@faker-js/faker'

import { OrganizationDocument } from '#shared/entities/organization/graphql/queries/organization.api.ts'
import { UserDocument } from '#shared/entities/user/graphql/queries/user.api.ts'
import type { Ticket } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { generateObjectData, mockOperation } from '../index.ts'

describe('correctly mocks operations', () => {
  describe('mocking organization', () => {
    const organizations: unknown[] = []

    it('always have a single organization by default', () => {
      const mock = mockOperation(OrganizationDocument, {})
      organizations.push(mock.organization)
      expect(mock).toHaveProperty('organization')
      expect(mock.organization).toHaveProperty('__typename', 'Organization')
      expect(mock.organization).toHaveProperty(
        'id',
        convertToGraphQLId('Organization', 1),
      )
      // we don't have members by default because it might go into a loop
      expect(mock.organization.members).toEqual({
        edges: [],
        totalCount: 0,
        __typename: 'UserConnection',
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: null,
          endCursor: null,
        },
      })
      const mock2 = mockOperation(OrganizationDocument, {})
      organizations.push(mock2.organization)
      expect(mock2.organization, 'correctly caches').toBe(mock.organization)
    })

    it('generates a different organization in another test', () => {
      const mock = mockOperation(OrganizationDocument, {})
      expect(mock.organization).toSatisfy(
        (organization) => !organizations.includes(organization),
      )
    })
  })

  describe('generating a user', () => {
    it('populates organization members', () => {
      const { user } = mockOperation(UserDocument, {})
      const { organization } = mockOperation(OrganizationDocument, {})

      expect(user.organization).toBe(organization)
      expect(organization.members.totalCount).toBe(1)
      expect(organization.members.edges[0].node).toBe(user)
      expect(organization.members.edges[0].node.organization.members).toBe(
        organization.members,
      )

      const { user: user2 } = mockOperation(UserDocument, {})
      expect(user2.organization).toBe(organization)
      expect(organization.members.totalCount).toBe(2)
      expect(organization.members.edges[1].node).toBe(user2)
      expect(organization.members.edges[1].node.organization.members).toBe(
        organization.members,
      )
    })
  })

  it('correctly applies defaults', () => {
    const query = {
      user: {
        id: convertToGraphQLId('User', 555),
        organization: {
          id: convertToGraphQLId('Organization', 33),
        },
        objectAttributeValues: [
          {
            attribute: {
              name: faker.word.noun(),
              display: faker.lorem.sentence(),
            },
            value: faker.lorem.words(5),
          },
        ],
      },
    }
    const objectAttribute = query.user.objectAttributeValues[0]
    const { user } = mockOperation(UserDocument, {}, query)
    expect(user).toHaveProperty('id', query.user.id)
    expect(user.organization).toHaveProperty('id', query.user.organization.id)
    expect(user.objectAttributeValues).toHaveLength(1)
    expect(user.objectAttributeValues[0]).toMatchObject({
      __typename: 'ObjectAttributeValue',
      value: objectAttribute.value,
      renderedLink: expect.any(String),
      attribute: expect.objectContaining({
        __typename: 'ObjectManagerFrontendAttribute',
        display: objectAttribute.attribute.display,
        name: objectAttribute.attribute.name,
        dataType: expect.any(String),
      }),
    })
  })

  it('generater correctly merges nested factory and nested defaults', () => {
    const ticket = generateObjectData<Ticket>('Ticket', {
      policy: { update: true, destroy: true },
    })
    expect(ticket.policy).toMatchObject({
      __typename: 'PolicyTicket',
      update: true,
      agentReadAccess: false,
    })
  })

  it('fixes ID if its not in graphql format', () => {
    const { id } = generateObjectData<Ticket>('Ticket', { id: '1' })
    expect(id).toBe(convertToGraphQLId('Ticket', 1))
  })

  it('throws an error if ID is in invalid format', () => {
    expect(() => {
      generateObjectData<Ticket>('Ticket', { id: 'dsfsdffds' })
    }).toThrowErrorMatchingInlineSnapshot(
      `[Error: expected numerical or graphql id for Ticket, got dsfsdffds]`,
    )
  })
})
