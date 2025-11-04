import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './aiAssistanceTextToolsList.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockAiAssistanceTextToolsListQuery(defaults: Mocks.MockDefaultsValue<Types.AiAssistanceTextToolsListQuery, Types.AiAssistanceTextToolsListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AiAssistanceTextToolsListDocument, defaults)
}

export function waitForAiAssistanceTextToolsListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AiAssistanceTextToolsListQuery>(Operations.AiAssistanceTextToolsListDocument)
}

export function mockAiAssistanceTextToolsListQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.AiAssistanceTextToolsListDocument, message, extensions);
}
