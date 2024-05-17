// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  EnumObjectManagerObjects,
  type AutocompleteSearchObjectAttributeExternalDataSourceInput,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  getGraphQLMockCalls,
  mockGraphQLResult,
  mockedApolloClient,
} from '../mocks.ts'

import {
  TestAutocompleteArrayFirstLevel,
  TestAvatarDocument,
  TestTicketArticlesMultiple,
  TestUserDocument,
} from './queries.ts'
import { getQueryHandler } from './utils.ts'

import type {
  TestAutocompleteArrayFirstLevelQuery,
  TestAvatarQuery,
  TestTicketArticlesMultipleQuery,
  TestUserQuery,
  TestUserQueryVariables,
} from './queries.ts'

describe('calling queries without mocking document works correctly', () => {
  it('client is defined', () => {
    expect(mockedApolloClient).toBeDefined()
  })

  it('query correctly returns data', async () => {
    expect(getGraphQLMockCalls(TestAvatarDocument)).toHaveLength(0)

    const handler = getQueryHandler<TestAvatarQuery>(TestAvatarDocument)
    const { data } = await handler.query()
    const { data: mocked } = handler.getMockedData()

    // mocked has more fields because it contains the whole object
    expect(mocked).toMatchObject(data!)
    expect(data).not.toMatchObject(mocked)

    expect(mocked).toHaveProperty('userCurrentAvatarActive.updatedBy')
    expect(data).not.toHaveProperty('userCurrentAvatarActive.updatedBy')
  })

  it('when user is already created, return it if variable is referencing it', async () => {
    expect(getGraphQLMockCalls(TestAvatarDocument)).toHaveLength(0)
    const handler = getQueryHandler<TestUserQuery, TestUserQueryVariables>(
      TestUserDocument,
    )

    const userId = convertToGraphQLId('User', 42)

    const { data } = await handler.query({
      variables: {
        userId,
      },
    })

    const { data: mocked } = handler.getMockedData()

    expect(data?.user.id).toBe(userId)
    expect(data?.user.id).toBe(mocked.user.id)
    expect(data?.user.fullname).toBe(mocked.user.fullname)

    const { data: data2 } = await handler.query({
      variables: {
        userId,
      },
    })

    expect(data2?.user.id).toBe(userId)
    expect(data2?.user.id).toBe(data?.user.id)
    expect(data2?.user.fullname).toBe(data?.user.fullname)

    const userIdNext = convertToGraphQLId('User', 43)
    const { data: data3 } = await handler.query({
      variables: {
        userId: userIdNext,
      },
    })

    expect(data3?.user.id).toBe(userIdNext)
  })
})

describe('calling queries with mocked data works correctly', () => {
  it('query correctly uses default data when generating a new item each time', async () => {
    expect(getGraphQLMockCalls(TestAvatarDocument)).toHaveLength(0)

    const exampleImage = 'https://example.com/image.png'

    mockGraphQLResult<TestAvatarQuery>(TestAvatarDocument, {
      userCurrentAvatarActive: {
        imageFull: exampleImage,
      },
    })

    const handler = getQueryHandler<TestAvatarQuery>(TestAvatarDocument)
    const { data } = await handler.query()
    const { data: mock } = handler.getMockedData()

    expect(data).toHaveProperty(
      'userCurrentAvatarActive.imageFull',
      exampleImage,
    )
    expect(mock).toHaveProperty(
      'userCurrentAvatarActive.imageFull',
      exampleImage,
    )

    const exampleImage2 = 'https://example.com/image2.png'

    mockGraphQLResult<TestAvatarQuery>(TestAvatarDocument, {
      userCurrentAvatarActive: {
        imageFull: exampleImage2,
      },
    })

    const { data: data2 } = await handler.query({ fetchPolicy: 'network-only' })
    const { data: mock2 } = handler.getMockedData()

    expect(mock2).toHaveProperty(
      'userCurrentAvatarActive.imageFull',
      exampleImage2,
    )
    expect(data2).toHaveProperty(
      'userCurrentAvatarActive.imageFull',
      exampleImage2,
    )
  })

  it('query correctly uses default data when updating the same object', async () => {
    expect(getGraphQLMockCalls(TestAvatarDocument)).toHaveLength(0)

    const exampleImage = 'https://example.com/image.png'

    mockGraphQLResult<TestAvatarQuery>(TestAvatarDocument, {
      userCurrentAvatarActive: {
        imageFull: exampleImage,
      },
    })

    const handler = getQueryHandler<TestAvatarQuery>(TestAvatarDocument)
    const { data } = await handler.query()
    const { data: mock } = handler.getMockedData()

    expect(data).toHaveProperty(
      'userCurrentAvatarActive.imageFull',
      exampleImage,
    )
    expect(mock).toHaveProperty(
      'userCurrentAvatarActive.imageFull',
      exampleImage,
    )

    const exampleImage2 = 'https://example.com/image2.png'

    mockGraphQLResult<TestAvatarQuery>(TestAvatarDocument, {
      userCurrentAvatarActive: {
        id: data?.userCurrentAvatarActive.id,
        imageFull: exampleImage2,
      },
    })

    const { data: data2 } = await handler.query({ fetchPolicy: 'network-only' })
    const { data: mock2 } = handler.getMockedData()

    expect(mock2).toHaveProperty(
      'userCurrentAvatarActive.imageFull',
      exampleImage2,
    )
    expect(data2).toHaveProperty(
      'userCurrentAvatarActive.imageFull',
      exampleImage2,
    )
  })

  it('when operation requests an array inside the first level, it correctly returns an array', async () => {
    const handler = getQueryHandler<
      TestAutocompleteArrayFirstLevelQuery,
      {
        input: AutocompleteSearchObjectAttributeExternalDataSourceInput
      }
    >(TestAutocompleteArrayFirstLevel)
    const { data } = await handler.query({
      variables: {
        input: {
          query: 'test',
          attributeName: 'test',
          object: EnumObjectManagerObjects.Ticket,
          templateRenderContext: {},
        },
      },
    })
    const { data: mocked } = handler.getMockedData()

    expect(
      data?.autocompleteSearchObjectAttributeExternalDataSource,
    ).toBeInstanceOf(Array)
    expect(
      mocked?.autocompleteSearchObjectAttributeExternalDataSource,
    ).toBeInstanceOf(Array)

    expect(
      data?.autocompleteSearchObjectAttributeExternalDataSource.length,
    ).toBe(mocked?.autocompleteSearchObjectAttributeExternalDataSource.length)
    expect(mocked).toMatchObject(data!)
  })

  it('query that references itself correctly returns data', async () => {
    const handler = getQueryHandler<
      TestTicketArticlesMultipleQuery,
      {
        ticketId: string
      }
    >(TestTicketArticlesMultiple)

    const { data, error } = await handler.query({
      variables: {
        ticketId: convertToGraphQLId('Ticket', 42),
      },
    })
    const { data: mock } = handler.getMockedData()

    expect(error).toBeUndefined()
    expect(data).toHaveProperty(
      'description.edges.0.node.bodyWithUrls',
      mock.description.edges[0].node.bodyWithUrls,
    )
    expect(data).toHaveProperty('articles.totalCount', mock.articles.totalCount)
    expect(data).toHaveProperty(
      'articles.edges.0.node.bodyWithUrls',
      mock.articles.edges[0].node.bodyWithUrls,
    )
  })
})
