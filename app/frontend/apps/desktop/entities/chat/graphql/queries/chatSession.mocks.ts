import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './chatSession.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockChatSessionQuery(defaults: Mocks.MockDefaultsValue<Types.ChatSessionQuery, Types.ChatSessionQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChatSessionDocument, defaults)
}

export function waitForChatSessionQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChatSessionQuery>(Operations.ChatSessionDocument)
}

export function mockChatSessionQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.ChatSessionDocument, message, extensions);
}
