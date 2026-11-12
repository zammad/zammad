import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './chatAgentAvailabilityUpdate.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockChatAgentAvailabilityUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.ChatAgentAvailabilityUpdateMutation, Types.ChatAgentAvailabilityUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChatAgentAvailabilityUpdateDocument, defaults)
}

export function waitForChatAgentAvailabilityUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChatAgentAvailabilityUpdateMutation>(Operations.ChatAgentAvailabilityUpdateDocument)
}

export function mockChatAgentAvailabilityUpdateMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.ChatAgentAvailabilityUpdateDocument, message, extensions);
}
