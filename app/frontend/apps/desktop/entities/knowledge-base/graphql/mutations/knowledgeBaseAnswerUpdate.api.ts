import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseAnswerAttributesFragmentDoc } from '../fragments/knowledgeBaseAnswerAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const KnowledgeBaseAnswerUpdateDocument = gql`
    mutation knowledgeBaseAnswerUpdate($answerId: ID!, $input: KnowledgeBaseUpdateAnswerInput!, $locale: String!, $meta: KnowledgeBaseAnswerUpdateMetaInput, $withBodyForEditing: Boolean = false) {
  knowledgeBaseAnswerUpdate(
    answerId: $answerId
    input: $input
    locale: $locale
    meta: $meta
  ) {
    answer {
      id
      ...knowledgeBaseAnswerAttributes
    }
    errors {
      ...errors
    }
  }
}
    ${KnowledgeBaseAnswerAttributesFragmentDoc}
${ErrorsFragmentDoc}`;
export function useKnowledgeBaseAnswerUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseAnswerUpdateMutation, Types.KnowledgeBaseAnswerUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseAnswerUpdateMutation, Types.KnowledgeBaseAnswerUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseAnswerUpdateMutation, Types.KnowledgeBaseAnswerUpdateMutationVariables>(KnowledgeBaseAnswerUpdateDocument, options);
}
export type KnowledgeBaseAnswerUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.KnowledgeBaseAnswerUpdateMutation, Types.KnowledgeBaseAnswerUpdateMutationVariables>;