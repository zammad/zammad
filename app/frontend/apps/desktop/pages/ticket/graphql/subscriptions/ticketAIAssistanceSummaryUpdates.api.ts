import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { AiAssistantAnalyticsMetaFragmentDoc } from '../fragments/AIAnalyticsMeta.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketAiAssistanceSummaryUpdatesDocument = gql`
    subscription ticketAIAssistanceSummaryUpdates($ticketId: ID!, $locale: String!) {
  ticketAIAssistanceSummaryUpdates(ticketId: $ticketId, locale: $locale) {
    summary {
      customerRequest
      conversationSummary
      openQuestions
      upcomingEvents
      customerMood
      customerEmotion
    }
    error {
      message
      exception
    }
    analytics {
      ...AIAssistantAnalyticsMeta
      isUnread
    }
  }
}
    ${AiAssistantAnalyticsMetaFragmentDoc}`;
export function useTicketAiAssistanceSummaryUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.TicketAiAssistanceSummaryUpdatesSubscription, Types.TicketAiAssistanceSummaryUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.TicketAiAssistanceSummaryUpdatesSubscription, Types.TicketAiAssistanceSummaryUpdatesSubscriptionVariables>(TicketAiAssistanceSummaryUpdatesDocument, options);
}
export type TicketAiAssistanceSummaryUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.TicketAiAssistanceSummaryUpdatesSubscription, Types.TicketAiAssistanceSummaryUpdatesSubscriptionVariables>;