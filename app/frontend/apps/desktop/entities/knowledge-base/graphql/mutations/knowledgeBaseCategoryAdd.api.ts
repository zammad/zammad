import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseCategoryGridAttributesFragmentDoc } from '../fragments/knowledgeBaseCategoryGridAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const KnowledgeBaseCategoryAddDocument = gql`
    mutation knowledgeBaseCategoryAdd($input: KnowledgeBaseCategoryInput!, $locale: String!) {
  knowledgeBaseCategoryAdd(input: $input, locale: $locale) {
    category {
      ...knowledgeBaseCategoryGridAttributes
    }
    errors {
      ...errors
    }
  }
}
    ${KnowledgeBaseCategoryGridAttributesFragmentDoc}
${ErrorsFragmentDoc}`;
export function useKnowledgeBaseCategoryAddMutation(options: VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseCategoryAddMutation, Types.KnowledgeBaseCategoryAddMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseCategoryAddMutation, Types.KnowledgeBaseCategoryAddMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseCategoryAddMutation, Types.KnowledgeBaseCategoryAddMutationVariables>(KnowledgeBaseCategoryAddDocument, options);
}
export type KnowledgeBaseCategoryAddMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.KnowledgeBaseCategoryAddMutation, Types.KnowledgeBaseCategoryAddMutationVariables>;