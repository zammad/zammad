import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ctiLogDoneUpdate.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockCtiLogDoneUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.CtiLogDoneUpdateMutation, Types.CtiLogDoneUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.CtiLogDoneUpdateDocument, defaults)
}

export function waitForCtiLogDoneUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.CtiLogDoneUpdateMutation>(Operations.CtiLogDoneUpdateDocument)
}

export function mockCtiLogDoneUpdateMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.CtiLogDoneUpdateDocument, message, extensions);
}
