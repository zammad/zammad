import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketAiRelatedKnowledgeBaseAnswersUpdatesDocument = gql`
    subscription ticketAIRelatedKnowledgeBaseAnswersUpdates($ticketId: ID!) {
  ticketAIRelatedKnowledgeBaseAnswersUpdates(ticketId: $ticketId) {
    ticketId
    error
  }
}
    `;
export function useTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscription, Types.TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscription, Types.TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionVariables>(TicketAiRelatedKnowledgeBaseAnswersUpdatesDocument, options);
}
export type TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscription, Types.TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionVariables>;