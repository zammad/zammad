import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentDeviceList.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentDeviceListQuery(defaults: Mocks.MockDefaultsValue<Types.UserCurrentDeviceListQuery, Types.UserCurrentDeviceListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentDeviceListDocument, defaults)
}

export function waitForUserCurrentDeviceListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentDeviceListQuery>(Operations.UserCurrentDeviceListDocument)
}

export function mockUserCurrentDeviceListQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentDeviceListDocument, message, extensions);
}
