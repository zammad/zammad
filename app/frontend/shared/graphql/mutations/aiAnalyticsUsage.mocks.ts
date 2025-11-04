import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './aiAnalyticsUsage.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockAiAnalyticsUsageMutation(defaults: Mocks.MockDefaultsValue<Types.AiAnalyticsUsageMutation, Types.AiAnalyticsUsageMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.AiAnalyticsUsageDocument, defaults)
}

export function waitForAiAnalyticsUsageMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AiAnalyticsUsageMutation>(Operations.AiAnalyticsUsageDocument)
}

export function mockAiAnalyticsUsageMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.AiAnalyticsUsageDocument, message, extensions);
}
