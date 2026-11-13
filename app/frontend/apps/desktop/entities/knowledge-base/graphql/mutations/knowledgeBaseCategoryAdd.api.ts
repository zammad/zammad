import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseCategoryGridAttributesFragmentDoc } from '../fragments/knowledgeBaseCategoryGridAttributes.api';
import { KnowledgeBaseCategoryPolicyFragmentDoc } from '../fragments/knowledgeBaseCategoryPolicy.api';
import { KnowledgeBaseCategoryPreInfoFragmentDoc } from '../fragments/knowledgeBaseCategoryPreInfo.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
${KnowledgeBaseCategoryPolicyFragmentDoc}
${KnowledgeBaseCategoryPreInfoFragmentDoc}
${ErrorsFragmentDoc}`;
export function useKnowledgeBaseCategoryAddMutation(options: VueApolloComposable.useMutation.Options<Types.KnowledgeBaseCategoryAddMutation, Types.KnowledgeBaseCategoryAddMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseCategoryAddMutation, Types.KnowledgeBaseCategoryAddMutationVariables>(KnowledgeBaseCategoryAddDocument, options);
}
export type KnowledgeBaseCategoryAddMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.KnowledgeBaseCategoryAddMutation, Types.KnowledgeBaseCategoryAddMutationVariables>;