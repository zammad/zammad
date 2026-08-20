import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseCategoryPolicyFragmentDoc } from '../fragments/knowledgeBaseCategoryPolicy.api';
import { KnowledgeBaseCategoryPreInfoFragmentDoc } from '../fragments/knowledgeBaseCategoryPreInfo.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const KnowledgeBaseCategoryAddDocument = gql`
    mutation knowledgeBaseCategoryAdd($knowledgeBaseId: ID!, $input: KnowledgeBaseCategoryInput!, $locale: String!) {
  knowledgeBaseCategoryAdd(
    knowledgeBaseId: $knowledgeBaseId
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
export function useKnowledgeBaseCategoryAddMutation(options: VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseCategoryAddMutation, Types.KnowledgeBaseCategoryAddMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseCategoryAddMutation, Types.KnowledgeBaseCategoryAddMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseCategoryAddMutation, Types.KnowledgeBaseCategoryAddMutationVariables>(KnowledgeBaseCategoryAddDocument, options);
}
export type KnowledgeBaseCategoryAddMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.KnowledgeBaseCategoryAddMutation, Types.KnowledgeBaseCategoryAddMutationVariables>;