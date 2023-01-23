import * as Types from '../../../../../../../../../graphql/types';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const KnowledgeBaseAnswerSuggestionContentTransformDocument = gql`
    mutation knowledgeBaseAnswerSuggestionContentTransform($translationId: ID!, $formId: FormId!) {
  knowledgeBaseAnswerSuggestionContentTransform(
    translationId: $translationId
    formId: $formId
  ) {
    body
    attachments {
      internalId
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
export function useKnowledgeBaseAnswerSuggestionContentTransformMutation(options: VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseAnswerSuggestionContentTransformMutation, Types.KnowledgeBaseAnswerSuggestionContentTransformMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseAnswerSuggestionContentTransformMutation, Types.KnowledgeBaseAnswerSuggestionContentTransformMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseAnswerSuggestionContentTransformMutation, Types.KnowledgeBaseAnswerSuggestionContentTransformMutationVariables>(KnowledgeBaseAnswerSuggestionContentTransformDocument, options);
}
export type KnowledgeBaseAnswerSuggestionContentTransformMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.KnowledgeBaseAnswerSuggestionContentTransformMutation, Types.KnowledgeBaseAnswerSuggestionContentTransformMutationVariables>;