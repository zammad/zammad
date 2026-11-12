import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const KnowledgeBaseAnswerSuggestionContentTransformDocument = gql`
    mutation knowledgeBaseAnswerSuggestionContentTransform($translationId: ID!, $formId: FormId!) {
  knowledgeBaseAnswerSuggestionContentTransform(
    translationId: $translationId
    formId: $formId
  ) {
    body
    attachments {
      id
      name
      size
      type
      preferences
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useKnowledgeBaseAnswerSuggestionContentTransformMutation(options: VueApolloComposable.useMutation.Options<Types.KnowledgeBaseAnswerSuggestionContentTransformMutation, Types.KnowledgeBaseAnswerSuggestionContentTransformMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseAnswerSuggestionContentTransformMutation, Types.KnowledgeBaseAnswerSuggestionContentTransformMutationVariables>(KnowledgeBaseAnswerSuggestionContentTransformDocument, options);
}
export type KnowledgeBaseAnswerSuggestionContentTransformMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.KnowledgeBaseAnswerSuggestionContentTransformMutation, Types.KnowledgeBaseAnswerSuggestionContentTransformMutationVariables>;