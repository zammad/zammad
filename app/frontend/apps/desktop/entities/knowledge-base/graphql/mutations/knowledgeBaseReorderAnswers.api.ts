import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const KnowledgeBaseReorderAnswersDocument = gql`
    mutation knowledgeBaseReorderAnswers($categoryId: ID!, $sortingMode: EnumKnowledgeBaseSortingMode!, $answerIds: [ID!]) {
  knowledgeBaseReorderAnswers(
    categoryId: $categoryId
    sortingMode: $sortingMode
    answerIds: $answerIds
  ) {
    category {
      id
      answerSortingMode
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useKnowledgeBaseReorderAnswersMutation(options: VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseReorderAnswersMutation, Types.KnowledgeBaseReorderAnswersMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseReorderAnswersMutation, Types.KnowledgeBaseReorderAnswersMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseReorderAnswersMutation, Types.KnowledgeBaseReorderAnswersMutationVariables>(KnowledgeBaseReorderAnswersDocument, options);
}
export type KnowledgeBaseReorderAnswersMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.KnowledgeBaseReorderAnswersMutation, Types.KnowledgeBaseReorderAnswersMutationVariables>;