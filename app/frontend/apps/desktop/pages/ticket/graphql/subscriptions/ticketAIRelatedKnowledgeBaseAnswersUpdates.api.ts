import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketAiRelatedKnowledgeBaseAnswersUpdatesDocument = gql`
    subscription ticketAIRelatedKnowledgeBaseAnswersUpdates($ticketId: ID!) {
  ticketAIRelatedKnowledgeBaseAnswersUpdates(ticketId: $ticketId) {
    ticketId
    error
  }
}
    `;
export function useTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscription(variables: Types.TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionVariables> | ReactiveFunction<Types.TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscription, Types.TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscription, Types.TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscription, Types.TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscription, Types.TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionVariables>(TicketAiRelatedKnowledgeBaseAnswersUpdatesDocument, variables, options);
}
export type TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscription, Types.TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionVariables>;