import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentAvatarSelect.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentAvatarSelectMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentAvatarSelectMutation, Types.UserCurrentAvatarSelectMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentAvatarSelectDocument, defaults)
}

export function waitForUserCurrentAvatarSelectMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentAvatarSelectMutation>(Operations.UserCurrentAvatarSelectDocument)
}

export function mockUserCurrentAvatarSelectMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentAvatarSelectDocument, message, extensions);
}
