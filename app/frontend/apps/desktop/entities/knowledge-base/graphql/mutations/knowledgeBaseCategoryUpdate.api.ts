import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseCategoryGridAttributesFragmentDoc } from '../fragments/knowledgeBaseCategoryGridAttributes.api';
import { KnowledgeBaseCategoryPolicyFragmentDoc } from '../fragments/knowledgeBaseCategoryPolicy.api';
import { KnowledgeBaseCategoryPreInfoFragmentDoc } from '../fragments/knowledgeBaseCategoryPreInfo.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const KnowledgeBaseCategoryUpdateDocument = gql`
    mutation knowledgeBaseCategoryUpdate($categoryId: ID!, $input: KnowledgeBaseCategoryInput!, $locale: String!) {
  knowledgeBaseCategoryUpdate(
    categoryId: $categoryId
    input: $input
    locale: $locale
  ) {
    category {
      ...knowledgeBaseCategoryGridAttributes
    }
    errors {
      ...errors
    }
  }
}
    ${KnowledgeBaseCategoryGridAttributesFragmentDoc}
${KnowledgeBaseCategoryPolicyFragmentDoc}
${KnowledgeBaseCategoryPreInfoFragmentDoc}
${ErrorsFragmentDoc}`;
export function useKnowledgeBaseCategoryUpdateMutation(options: VueApolloComposable.useMutation.Options<Types.KnowledgeBaseCategoryUpdateMutation, Types.KnowledgeBaseCategoryUpdateMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseCategoryUpdateMutation, Types.KnowledgeBaseCategoryUpdateMutationVariables>(KnowledgeBaseCategoryUpdateDocument, options);
}
export type KnowledgeBaseCategoryUpdateMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.KnowledgeBaseCategoryUpdateMutation, Types.KnowledgeBaseCategoryUpdateMutationVariables>;