import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketAiAssistanceEnqueueKnowledgeBaseAnswerDocument = gql`
    mutation ticketAIAssistanceEnqueueKnowledgeBaseAnswer($ticketId: ID!) {
  ticketAIAssistanceEnqueueKnowledgeBaseAnswer(ticketId: $ticketId) {
    success
  }
}
    `;
export function useTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation, Types.TicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation, Types.TicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation, Types.TicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationVariables>(TicketAiAssistanceEnqueueKnowledgeBaseAnswerDocument, options);
}
export type TicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation, Types.TicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationVariables>;