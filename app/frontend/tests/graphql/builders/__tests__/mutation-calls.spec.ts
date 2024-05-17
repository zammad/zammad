// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { faker } from '@faker-js/faker'

import UserError from '#shared/errors/UserError.ts'
import { LoginDocument } from '#shared/graphql/mutations/login.api.ts'
import type { MutationsUserCurrentAvatarAddArgs } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { getGraphQLMockCalls, mockGraphQLResult } from '../mocks.ts'

import {
  type TestAvatarMutation,
  TestAvatarActiveMutationDocument,
  TestUserUpdateDocument,
  type TestUserUpdateMutation,
  type TestUserUpdateVariables,
  TestUserDocument,
  type TestUserQuery,
  type TestUserQueryVariables,
  type TestUserSignupMutationQuery,
  TestUserSignupMutationDocument,
  type TestUserSignupArgs,
} from './queries.ts'
import { getMutationHandler, getQueryHandler } from './utils.ts'

describe('calling mutation without mocking document works correctly', () => {
  it('mutation correctly returns data', async () => {
    expect(getGraphQLMockCalls(TestAvatarActiveMutationDocument)).toHaveLength(
      0,
    )

    const handler = getMutationHandler<
      TestAvatarMutation,
      MutationsUserCurrentAvatarAddArgs
    >(TestAvatarActiveMutationDocument)
    const data = await handler.send({
      images: {
        original: { name: faker.word.noun() },
        resized: { name: faker.word.noun() },
      },
    })
    const { data: mocked } = handler.getMockedData()

    // errors is always null by default
    expect(data?.userCurrentAvatarAdd?.errors).toBeNull()
    expect(mocked).toMatchObject(data!)
    expect(data).not.toMatchObject(mocked)

    expect(mocked).toHaveProperty('userCurrentAvatarAdd.avatar.createdAt')
    expect(data).not.toHaveProperty('userCurrentAvatarAdd.avatar.createdAt')
  })

  it('mutation correctly processed data with arrays', async () => {
    expect(getGraphQLMockCalls(TestUserUpdateDocument)).toHaveLength(0)

    const handler = getMutationHandler<
      TestUserUpdateMutation,
      TestUserUpdateVariables
    >(TestUserUpdateDocument)

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
    expect(getGraphQLMockCalls(TestUserDocument)).toHaveLength(0)

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
      TestUserUpdateMutation,
      TestUserUpdateVariables
    >(TestUserUpdateDocument)

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
    expect(getGraphQLMockCalls(TestAvatarActiveMutationDocument)).toHaveLength(
      0,
    )

    const avatarId = convertToGraphQLId('Avatar', 42)
    const imageFull = 'https://example.com/image.png'
    mockGraphQLResult(TestAvatarActiveMutationDocument, {
      userCurrentAvatarAdd: {
        avatar: {
          id: avatarId,
          imageFull,
        },
      },
    })

    const handler = getMutationHandler<
      TestAvatarMutation,
      MutationsUserCurrentAvatarAddArgs
    >(TestAvatarActiveMutationDocument)
    const data = await handler.send({
      images: {
        original: { name: faker.word.noun() },
        resized: { name: faker.word.noun() },
      },
    })

    expect(data?.userCurrentAvatarAdd?.avatar).toEqual({
      __typename: 'Avatar',
      id: avatarId,
      imageFull,
    })

    const { data: mocked } = handler.getMockedData()

    expect(mocked.userCurrentAvatarAdd.avatar).toHaveProperty('id', avatarId)
    expect(mocked.userCurrentAvatarAdd.avatar).toHaveProperty(
      'imageFull',
      imageFull,
    )
  })

  it('correctly returns errors if provided', async () => {
    mockGraphQLResult(TestAvatarActiveMutationDocument, {
      userCurrentAvatarAdd: {
        errors: [
          {
            message: 'Some error',
          },
        ],
      },
    })

    const handler = getMutationHandler<
      TestAvatarMutation,
      MutationsUserCurrentAvatarAddArgs
    >(TestAvatarActiveMutationDocument)
    const data = await handler
      .send({
        images: {
          original: { name: faker.word.noun() },
          resized: { name: faker.word.noun() },
        },
      })
      .catch((e) => e)

    expect(data).toBeInstanceOf(UserError)
    expect(data.errors).toHaveLength(1)
    expect(data.errors[0].message).toBe('Some error')
  })

  it('mutation is always successful by defualt', async () => {
    const handler = getMutationHandler<
      TestUserSignupMutationQuery,
      TestUserSignupArgs
    >(TestUserSignupMutationDocument)

    const data = await handler.send({
      input: {
        email: faker.internet.userName(),
        password: faker.internet.password(),
      },
    })
    expect(data?.userSignup.success).toBe(true)
    expect(data?.userSignup.errors).toBeNull()
  })

  describe('correctly validates variables', () => {
    it('throws an error if field is required, but not defined', async () => {
      const handler = getMutationHandler(TestUserSignupMutationDocument)

      await expect(() =>
        handler.send({}),
      ).rejects.toThrowErrorMatchingInlineSnapshot(
        `[ApolloError: (Variables error for mutation userSignup) non-nullable field "input" is not defined]`,
      )
    })

    it('throws an error if field is required inside the list, but not defined', async () => {
      const mutationHandler = getMutationHandler(TestUserUpdateDocument)

      await expect(() =>
        mutationHandler.send({
          userId: '1',
          input: {
            objectAttributeValues: [{}],
          },
        }),
      ).rejects.toThrowErrorMatchingInlineSnapshot(
        `[ApolloError: (Variables error for mutation userUpdate) non-nullable field "name" is not defined]`,
      )
    })

    it('throws an error if field is not defined on the inner type', async () => {
      const handler = getMutationHandler(TestUserSignupMutationDocument)

      await expect(() =>
        handler.send({
          input: { email: 'email', password: 'password', invalidField: true },
        }),
      ).rejects.toThrowErrorMatchingInlineSnapshot(
        `[ApolloError: (Variables error for mutation userSignup) field "invalidField" is not defined on UserSignupInput]`,
      )
    })

    it('throws an error if field is not defined on the outer type', async () => {
      const handler = getMutationHandler(TestUserSignupMutationDocument)

      await expect(() =>
        handler.send({
          invalidField: true,
          input: { email: 'email', password: 'password' },
        }),
      ).rejects.toThrowErrorMatchingInlineSnapshot(
        `[ApolloError: (Variables error for mutation userSignup) field "invalidField" is not defined on mutation userSignup]`,
      )
    })

    it('throws an error if field is not defined on the type inside the list', async () => {
      const mutationHandler = getMutationHandler(TestUserUpdateDocument)

      await expect(() =>
        mutationHandler.send({
          userId: '1',
          input: {
            objectAttributeValues: [{ invalidField: true }],
          },
        }),
      ).rejects.toThrowErrorMatchingInlineSnapshot(
        `[ApolloError: (Variables error for mutation userUpdate) field "invalidField" is not defined on ObjectAttributeValueInput]`,
      )
    })

    it('throws an error if field is not the correct scalar type', async () => {
      const handler = getMutationHandler(TestUserSignupMutationDocument)

      await expect(() =>
        handler.send({
          input: { email: 123, password: 'password' },
        }),
      ).rejects.toThrowErrorMatchingInlineSnapshot(
        `[ApolloError: (Variables error for mutation userSignup) expected string for "email", got number]`,
      )
    })

    it('throws an error if field is not the correct object type', async () => {
      const handler = getMutationHandler(TestUserSignupMutationDocument)

      await expect(() =>
        handler.send({
          input: 123,
        }),
      ).rejects.toThrowErrorMatchingInlineSnapshot(
        `[ApolloError: (Variables error for mutation userSignup) expected object for "input", got number]`,
      )
    })

    it('throws an error if field is not the correct type inside the list', async () => {
      const mutationHandler = getMutationHandler(TestUserUpdateDocument)

      await expect(() =>
        mutationHandler.send({
          userId: '1',
          input: {
            objectAttributeValues: [{ name: 123 }],
          },
        }),
      ).rejects.toThrowErrorMatchingInlineSnapshot(
        `[ApolloError: (Variables error for mutation userUpdate) expected string for "name", got number]`,
      )
    })

    it('throws an error if field is not in enum', async () => {
      const mutationHandler = getMutationHandler(LoginDocument)

      await expect(() =>
        mutationHandler.send({
          input: {
            login: 'login',
            password: 'password',
            rememberMe: true,
            twoFactorAuthentication: {
              twoFactorMethod: 'unknown_method_to_test_error',
              twoFactorPayload: 'some_payload',
            },
          },
        }),
      ).rejects.toThrowErrorMatchingInlineSnapshot(
        `[ApolloError: (Variables error for mutation login) twoFactorMethod should be one of "security_keys", "authenticator_app", but instead got "unknown_method_to_test_error"]`,
      )
    })
  })
})
