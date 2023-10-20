// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import {
  getGraphQLResult,
  mockGraphQLResult,
  mockedApolloClient,
} from '../mocks.ts'
import { TestAvatarDocument, TestUserDocument } from './queries.ts'
import type {
  TestAvatarQuery,
  TestUserQuery,
  TestUserQueryVariables,
} from './queries.ts'
import { getQueryHandler } from './utils.ts'

describe('calling queries without mocking document works correctly', () => {
  it('client is defined', () => {
    expect(mockedApolloClient).toBeDefined()
  })

  it('query correctly returns data', async () => {
    expect(getGraphQLResult(TestAvatarDocument)).toBeUndefined()

    const handler = getQueryHandler<TestAvatarQuery>(TestAvatarDocument)
    const { data } = await handler.query()
    const { data: mocked } = handler.getMockedData()

    // mocked has more fields because it contains the whole object
    expect(mocked).toMatchObject(data!)
    expect(data).not.toMatchObject(mocked)

    expect(mocked).toHaveProperty('accountAvatarActive.updatedBy')
    expect(data).not.toHaveProperty('accountAvatarActive.updatedBy')
  })

  it('when user is already created, return it if variable is referencing it', async () => {
    expect(getGraphQLResult(TestAvatarDocument)).toBeUndefined()
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
    expect(getGraphQLResult(TestAvatarDocument)).toBeUndefined()

    const exampleImage = 'https://example.com/image.png'

    mockGraphQLResult<TestAvatarQuery>(TestAvatarDocument, {
      accountAvatarActive: {
        imageFull: exampleImage,
      },
    })

    const handler = getQueryHandler<TestAvatarQuery>(TestAvatarDocument)
    const { data } = await handler.query()
    const { data: mock } = handler.getMockedData()

    expect(data).toHaveProperty('accountAvatarActive.imageFull', exampleImage)
    expect(mock).toHaveProperty('accountAvatarActive.imageFull', exampleImage)

    const exampleImage2 = 'https://example.com/image2.png'

    mockGraphQLResult<TestAvatarQuery>(TestAvatarDocument, {
      accountAvatarActive: {
        imageFull: exampleImage2,
      },
    })

    const { data: data2 } = await handler.query({ fetchPolicy: 'network-only' })
    const { data: mock2 } = handler.getMockedData()

    expect(mock2).toHaveProperty('accountAvatarActive.imageFull', exampleImage2)
    expect(data2).toHaveProperty('accountAvatarActive.imageFull', exampleImage2)
  })

  it('query correctly uses default data when updating the same object', async () => {
    expect(getGraphQLResult(TestAvatarDocument)).toBeUndefined()

    const exampleImage = 'https://example.com/image.png'

    mockGraphQLResult<TestAvatarQuery>(TestAvatarDocument, {
      accountAvatarActive: {
        imageFull: exampleImage,
      },
    })

    const handler = getQueryHandler<TestAvatarQuery>(TestAvatarDocument)
    const { data } = await handler.query()
    const { data: mock } = handler.getMockedData()

    expect(data).toHaveProperty('accountAvatarActive.imageFull', exampleImage)
    expect(mock).toHaveProperty('accountAvatarActive.imageFull', exampleImage)

    const exampleImage2 = 'https://example.com/image2.png'

    mockGraphQLResult<TestAvatarQuery>(TestAvatarDocument, {
      accountAvatarActive: {
        id: data?.accountAvatarActive.id,
        imageFull: exampleImage2,
      },
    })

    const { data: data2 } = await handler.query({ fetchPolicy: 'network-only' })
    const { data: mock2 } = handler.getMockedData()

    expect(mock2).toHaveProperty('accountAvatarActive.imageFull', exampleImage2)
    expect(data2).toHaveProperty('accountAvatarActive.imageFull', exampleImage2)
  })
})
