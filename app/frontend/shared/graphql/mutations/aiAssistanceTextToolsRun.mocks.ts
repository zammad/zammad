import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './aiAssistanceTextToolsRun.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockAiAssistanceTextToolsRunMutation(defaults: Mocks.MockDefaultsValue<Types.AiAssistanceTextToolsRunMutation, Types.AiAssistanceTextToolsRunMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.AiAssistanceTextToolsRunDocument, defaults)
}

export function waitForAiAssistanceTextToolsRunMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AiAssistanceTextToolsRunMutation>(Operations.AiAssistanceTextToolsRunDocument)
}

export function mockAiAssistanceTextToolsRunMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.AiAssistanceTextToolsRunDocument, message, extensions);
}
