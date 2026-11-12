import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './chatAgentState.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockChatAgentStateQuery(defaults: Mocks.MockDefaultsValue<Types.ChatAgentStateQuery, Types.ChatAgentStateQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChatAgentStateDocument, defaults)
}

export function waitForChatAgentStateQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChatAgentStateQuery>(Operations.ChatAgentStateDocument)
}

export function mockChatAgentStateQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.ChatAgentStateDocument, message, extensions);
}
