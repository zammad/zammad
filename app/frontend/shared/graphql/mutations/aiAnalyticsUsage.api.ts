import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const AiAnalyticsUsageDocument = gql`
    mutation aiAnalyticsUsage($aiAnalyticsRunId: ID!, $input: AIAnalyticsUsageInput!) {
  aiAnalyticsUsage(aiAnalyticsRunId: $aiAnalyticsRunId, input: $input) {
    usage {
      id
    }
  }
}
    `;
export function useAiAnalyticsUsageMutation(options: VueApolloComposable.useMutation.Options<Types.AiAnalyticsUsageMutation, Types.AiAnalyticsUsageMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.AiAnalyticsUsageMutation, Types.AiAnalyticsUsageMutationVariables>(AiAnalyticsUsageDocument, options);
}
export type AiAnalyticsUsageMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.AiAnalyticsUsageMutation, Types.AiAnalyticsUsageMutationVariables>;