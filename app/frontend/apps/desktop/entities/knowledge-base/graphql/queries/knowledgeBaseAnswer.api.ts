import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseAnswerAttributesFragmentDoc } from '../fragments/knowledgeBaseAnswerAttributes.api';
import { KnowledgeBaseAnswerPolicyFragmentDoc } from '../fragments/knowledgeBaseAnswerPolicy.api';
import { KnowledgeBaseAnswerPreInfoFragmentDoc } from '../fragments/knowledgeBaseAnswerPreInfo.api';
import { KnowledgeBaseCategoryBreadcrumbFragmentDoc } from '../fragments/knowledgeBaseCategoryBreadcrumb.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const KnowledgeBaseAnswerDocument = gql`
    query knowledgeBaseAnswer($answerId: ID!, $locale: String, $withBodyForEditing: Boolean = false, $withNavigation: Boolean = true) {
  knowledgeBaseAnswer(answerId: $answerId, locale: $locale) {
    id
    ...knowledgeBaseAnswerAttributes
  }
}
    ${KnowledgeBaseAnswerAttributesFragmentDoc}
${KnowledgeBaseAnswerPolicyFragmentDoc}
${KnowledgeBaseAnswerPreInfoFragmentDoc}
${KnowledgeBaseCategoryBreadcrumbFragmentDoc}`;
export function useKnowledgeBaseAnswerQuery(options: VueApolloComposable.useQuery.Options<Types.KnowledgeBaseAnswerQuery, Types.KnowledgeBaseAnswerQueryVariables>) {
  return VueApolloComposable.useQuery<Types.KnowledgeBaseAnswerQuery, Types.KnowledgeBaseAnswerQueryVariables>(KnowledgeBaseAnswerDocument, options);
}
export function useKnowledgeBaseAnswerLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.KnowledgeBaseAnswerQuery, Types.KnowledgeBaseAnswerQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.KnowledgeBaseAnswerQuery, Types.KnowledgeBaseAnswerQueryVariables>(KnowledgeBaseAnswerDocument, options);
}
export type KnowledgeBaseAnswerQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.KnowledgeBaseAnswerQuery, Types.KnowledgeBaseAnswerQueryVariables>;