import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useKnowledgeBaseAnswerDeleteMutation(options: VueApolloComposable.useMutation.Options<Types.KnowledgeBaseAnswerDeleteMutation, Types.KnowledgeBaseAnswerDeleteMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseAnswerDeleteMutation, Types.KnowledgeBaseAnswerDeleteMutationVariables>(KnowledgeBaseAnswerDeleteDocument, options);
}
export type KnowledgeBaseAnswerDeleteMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.KnowledgeBaseAnswerDeleteMutation, Types.KnowledgeBaseAnswerDeleteMutationVariables>;