import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseCategoryPolicyFragmentDoc } from '../fragments/knowledgeBaseCategoryPolicy.api';
import { KnowledgeBaseCategoryPreInfoFragmentDoc } from '../fragments/knowledgeBaseCategoryPreInfo.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const KnowledgeBaseCategoryUpdateDocument = gql`
    mutation knowledgeBaseCategoryUpdate($categoryId: ID!, $input: KnowledgeBaseCategoryInput!, $locale: String!) {
  knowledgeBaseCategoryUpdate(
    categoryId: $categoryId
    input: $input
    locale: $locale
  ) {
    category {
      id
      title
      categoryIcon
      visibility
      translationMissing
      answerCount
      subcategoryCount
      position
      isDeletable
      ...knowledgeBaseCategoryPolicy
      ...knowledgeBaseCategoryPreInfo
    }
    errors {
      ...errors
    }
  }
}
    ${KnowledgeBaseCategoryPolicyFragmentDoc}
${KnowledgeBaseCategoryPreInfoFragmentDoc}
${ErrorsFragmentDoc}`;
export function useKnowledgeBaseCategoryUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseCategoryUpdateMutation, Types.KnowledgeBaseCategoryUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseCategoryUpdateMutation, Types.KnowledgeBaseCategoryUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseCategoryUpdateMutation, Types.KnowledgeBaseCategoryUpdateMutationVariables>(KnowledgeBaseCategoryUpdateDocument, options);
}
export type KnowledgeBaseCategoryUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.KnowledgeBaseCategoryUpdateMutation, Types.KnowledgeBaseCategoryUpdateMutationVariables>;