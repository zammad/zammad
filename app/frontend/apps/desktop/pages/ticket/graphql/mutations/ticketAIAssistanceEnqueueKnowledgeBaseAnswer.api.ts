import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketAiAssistanceEnqueueKnowledgeBaseAnswerDocument = gql`
    mutation ticketAIAssistanceEnqueueKnowledgeBaseAnswer($ticketId: ID!) {
  ticketAIAssistanceEnqueueKnowledgeBaseAnswer(ticketId: $ticketId) {
    success
  }
}
    `;
export function useTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation(options: VueApolloComposable.useMutation.Options<Types.TicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation, Types.TicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation, Types.TicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationVariables>(TicketAiAssistanceEnqueueKnowledgeBaseAnswerDocument, options);
}
export type TicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation, Types.TicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationVariables>;