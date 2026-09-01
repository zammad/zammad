import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const KnowledgeBaseAnswerDeleteDocument = gql`
    mutation knowledgeBaseAnswerDelete($answerId: ID!) {
  knowledgeBaseAnswerDelete(answerId: $answerId) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useKnowledgeBaseAnswerDeleteMutation(options: VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseAnswerDeleteMutation, Types.KnowledgeBaseAnswerDeleteMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseAnswerDeleteMutation, Types.KnowledgeBaseAnswerDeleteMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseAnswerDeleteMutation, Types.KnowledgeBaseAnswerDeleteMutationVariables>(KnowledgeBaseAnswerDeleteDocument, options);
}
export type KnowledgeBaseAnswerDeleteMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.KnowledgeBaseAnswerDeleteMutation, Types.KnowledgeBaseAnswerDeleteMutationVariables>;