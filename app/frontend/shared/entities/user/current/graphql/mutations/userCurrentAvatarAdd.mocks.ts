import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentAvatarAdd.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentAvatarAddMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentAvatarAddMutation, Types.UserCurrentAvatarAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentAvatarAddDocument, defaults)
}

export function waitForUserCurrentAvatarAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentAvatarAddMutation>(Operations.UserCurrentAvatarAddDocument)
}

export function mockUserCurrentAvatarAddMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentAvatarAddDocument, message, extensions);
}
