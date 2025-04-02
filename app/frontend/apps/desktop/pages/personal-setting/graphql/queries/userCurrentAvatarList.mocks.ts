import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentAvatarList.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentAvatarListQuery(defaults: Mocks.MockDefaultsValue<Types.UserCurrentAvatarListQuery, Types.UserCurrentAvatarListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentAvatarListDocument, defaults)
}

export function waitForUserCurrentAvatarListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentAvatarListQuery>(Operations.UserCurrentAvatarListDocument)
}

export function mockUserCurrentAvatarListQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentAvatarListDocument, message, extensions);
}
