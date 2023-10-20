// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { MutationsAccountAvatarAddArgs } from '#shared/graphql/types.ts'
import { faker } from '@faker-js/faker'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { getGraphQLResult, mockGraphQLResult } from '../mocks.ts'
import { getMutationHandler, getQueryHandler } from './utils.ts'
import {
  type TestAvatarMutation,
  TestAvatarActiveMutationDocument,
  TestUserAutorizationsDocument,
  type TestUserAuthorizationsMutation,
  type TestUserAuthorizationsVariables,
  TestUserDocument,
  type TestUserQuery,
  type TestUserQueryVariables,
} from './queries.ts'

describe('calling mutation without mocking document works correctly', () => {
  it('mutation correctly returns data', async () => {
    expect(getGraphQLResult(TestAvatarActiveMutationDocument)).toBeUndefined()

    const handler = getMutationHandler<
      TestAvatarMutation,
      MutationsAccountAvatarAddArgs
    >(TestAvatarActiveMutationDocument)
    const data = await handler.send({
      images: {
        original: { name: faker.word.noun() },
        resized: { name: faker.word.noun() },
      },
    })
    const { data: mocked } = handler.getMockedData()

    // errors is always null by default
    expect(data?.accountAvatarAdd?.errors).toBeNull()
    expect(mocked).toMatchObject(data!)
    expect(data).not.toMatchObject(mocked)

    expect(mocked).toHaveProperty('accountAvatarAdd.avatar.createdAt')
    expect(data).not.toHaveProperty('accountAvatarAdd.avatar.createdAt')
  })

  it('mutation correctly processed data with arrays', async () => {
    expect(getGraphQLResult(TestUserAutorizationsDocument)).toBeUndefined()

    const handler = getMutationHandler<
      TestUserAuthorizationsMutation,
      TestUserAuthorizationsVariables
    >(TestUserAutorizationsDocument)

    const userId = convertToGraphQLId('User', 42)

    const data = await handler.send({
      userId,
      input: {
        vip: false,
      },
    })

    const { data: mocked } = handler.getMockedData()

    expect(data?.userUpdate.user).toEqual({
      __typename: 'User',
      id: userId,
      fullname: mocked.userUpdate.user.fullname,
      authorizations: mocked.userUpdate.user.authorizations.map((auth) => ({
        id: auth.id,
        provider: auth.provider,
        __typename: 'Authorization',
      })),
    })
  })

  it('returns the same object if it already exists, but values are updated', async () => {
    expect(getGraphQLResult(TestUserDocument)).toBeUndefined()

    const queryHandler = getQueryHandler<TestUserQuery, TestUserQueryVariables>(
      TestUserDocument,
    )
    const userId = convertToGraphQLId('User', 42)
    const { data } = await queryHandler.query({
      variables: {
        userId,
      },
    })

    const currentFullname = data?.user?.fullname

    expect(data?.user).toEqual({
      __typename: 'User',
      id: userId,
      fullname: expect.any(String),
    })

    const mutationHandler = getMutationHandler<
      TestUserAuthorizationsMutation,
      TestUserAuthorizationsVariables
    >(TestUserAutorizationsDocument)

    const mutationData = await mutationHandler.send({
      userId,
      input: {
        vip: false,
        phone: '1234567890',
      },
    })

    const mutationUser = mutationData?.userUpdate.user

    expect(mutationUser?.id).toBe(userId)
    expect(mutationUser?.fullname).toBe(currentFullname)

    const { data: mockedQuery } = queryHandler.getMockedData()
    const { data: mockedMutation } = mutationHandler.getMockedData()

    expect(mockedQuery?.user).toBe(mockedMutation?.userUpdate.user)

    expect(mockedQuery?.user).toHaveProperty('vip', false)
    expect(mockedQuery?.user).toHaveProperty('phone', '1234567890')
  })
})

describe('calling mutation with mocked return data correctly returns data', () => {
  it('returns mocked data when mutation is mocked and then called', async () => {
    expect(getGraphQLResult(TestAvatarActiveMutationDocument)).toBeUndefined()

    const avatarId = convertToGraphQLId('Avatar', 42)
    const imageFull = 'https://example.com/image.png'
    mockGraphQLResult(TestAvatarActiveMutationDocument, {
      accountAvatarAdd: {
        avatar: {
          id: avatarId,
          imageFull,
        },
      },
    })

    const handler = getMutationHandler<
      TestAvatarMutation,
      MutationsAccountAvatarAddArgs
    >(TestAvatarActiveMutationDocument)
    const data = await handler.send({
      images: {
        original: { name: faker.word.noun() },
        resized: { name: faker.word.noun() },
      },
    })

    expect(data?.accountAvatarAdd?.avatar).toEqual({
      __typename: 'Avatar',
      id: avatarId,
      imageFull,
    })

    const { data: mocked } = handler.getMockedData()

    expect(mocked.accountAvatarAdd.avatar).toHaveProperty('id', avatarId)
    expect(mocked.accountAvatarAdd.avatar).toHaveProperty(
      'imageFull',
      imageFull,
    )
  })
})
