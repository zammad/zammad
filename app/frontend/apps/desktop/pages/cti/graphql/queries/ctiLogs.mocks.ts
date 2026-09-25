import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ctiLogs.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockCtiLogsQuery(defaults: Mocks.MockDefaultsValue<Types.CtiLogsQuery, Types.CtiLogsQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.CtiLogsDocument, defaults)
}

export function waitForCtiLogsQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.CtiLogsQuery>(Operations.CtiLogsDocument)
}

export function mockCtiLogsQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.CtiLogsDocument, message, extensions);
}
