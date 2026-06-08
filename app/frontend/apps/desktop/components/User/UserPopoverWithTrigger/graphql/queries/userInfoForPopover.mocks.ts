import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userInfoForPopover.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserInfoForPopoverQuery(defaults: Mocks.MockDefaultsValue<Types.UserInfoForPopoverQuery, Types.UserInfoForPopoverQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserInfoForPopoverDocument, defaults)
}

export function waitForUserInfoForPopoverQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserInfoForPopoverQuery>(Operations.UserInfoForPopoverDocument)
}

export function mockUserInfoForPopoverQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserInfoForPopoverDocument, message, extensions);
}
