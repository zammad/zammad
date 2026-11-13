import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { AiAssistantAnalyticsMetaFragmentDoc } from '../fragments/AIAnalyticsMeta.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketAiAssistanceSummarizeDocument = gql`
    mutation ticketAIAssistanceSummarize($ticketId: ID!, $regenerationOfId: ID) {
  ticketAIAssistanceSummarize(
    ticketId: $ticketId
    regenerationOfId: $regenerationOfId
  ) {
    summary {
      customerRequest
      conversationSummary
      openQuestions
      upcomingEvents
      customerMood
      customerEmotion
    }
    analytics {
      ...AIAssistantAnalyticsMeta
      isUnread
    }
  }
}
    ${AiAssistantAnalyticsMetaFragmentDoc}`;
export function useTicketAiAssistanceSummarizeMutation(options: VueApolloComposable.useMutation.Options<Types.TicketAiAssistanceSummarizeMutation, Types.TicketAiAssistanceSummarizeMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketAiAssistanceSummarizeMutation, Types.TicketAiAssistanceSummarizeMutationVariables>(TicketAiAssistanceSummarizeDocument, options);
}
export type TicketAiAssistanceSummarizeMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketAiAssistanceSummarizeMutation, Types.TicketAiAssistanceSummarizeMutationVariables>;