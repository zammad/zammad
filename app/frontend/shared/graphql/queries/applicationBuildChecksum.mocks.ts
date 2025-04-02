import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './applicationBuildChecksum.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockApplicationBuildChecksumQuery(defaults: Mocks.MockDefaultsValue<Types.ApplicationBuildChecksumQuery, Types.ApplicationBuildChecksumQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.ApplicationBuildChecksumDocument, defaults)
}

export function waitForApplicationBuildChecksumQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ApplicationBuildChecksumQuery>(Operations.ApplicationBuildChecksumDocument)
}

export function mockApplicationBuildChecksumQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.ApplicationBuildChecksumDocument, message, extensions);
}
