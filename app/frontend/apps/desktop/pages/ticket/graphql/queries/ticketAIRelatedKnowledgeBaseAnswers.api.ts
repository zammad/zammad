import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseAnswerTranslationFragmentDoc } from '../../../../entities/knowledge-base/graphql/fragments/knowledgeBaseAnswerTranslation.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketAiRelatedKnowledgeBaseAnswersDocument = gql`
    query ticketAIRelatedKnowledgeBaseAnswers($ticketId: ID!, $includeDraftsAndArchived: Boolean, $includeLinkedAnswers: Boolean) {
  ticketAIRelatedKnowledgeBaseAnswers(
    ticketId: $ticketId
    includeDraftsAndArchived: $includeDraftsAndArchived
    includeLinkedAnswers: $includeLinkedAnswers
  ) {
    pending
    answers {
      score
      translation {
        ...knowledgeBaseAnswerTranslation
      }
    }
  }
}
    ${KnowledgeBaseAnswerTranslationFragmentDoc}`;
export function useTicketAiRelatedKnowledgeBaseAnswersQuery(options: VueApolloComposable.useQuery.Options<Types.TicketAiRelatedKnowledgeBaseAnswersQuery, Types.TicketAiRelatedKnowledgeBaseAnswersQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketAiRelatedKnowledgeBaseAnswersQuery, Types.TicketAiRelatedKnowledgeBaseAnswersQueryVariables>(TicketAiRelatedKnowledgeBaseAnswersDocument, options);
}
export function useTicketAiRelatedKnowledgeBaseAnswersLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketAiRelatedKnowledgeBaseAnswersQuery, Types.TicketAiRelatedKnowledgeBaseAnswersQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketAiRelatedKnowledgeBaseAnswersQuery, Types.TicketAiRelatedKnowledgeBaseAnswersQueryVariables>(TicketAiRelatedKnowledgeBaseAnswersDocument, options);
}
export type TicketAiRelatedKnowledgeBaseAnswersQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketAiRelatedKnowledgeBaseAnswersQuery, Types.TicketAiRelatedKnowledgeBaseAnswersQueryVariables>;