import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseFeedAttributesFragmentDoc } from '../fragments/knowledgeBaseFeedAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const KnowledgeBaseFeedDocument = gql`
    query knowledgeBaseFeed($categoryId: ID, $locale: String) {
  knowledgeBaseFeed(categoryId: $categoryId, locale: $locale) {
    ...knowledgeBaseFeedAttributes
  }
}
    ${KnowledgeBaseFeedAttributesFragmentDoc}`;
export function useKnowledgeBaseFeedQuery(options: VueApolloComposable.useQuery.Options<Types.KnowledgeBaseFeedQuery, Types.KnowledgeBaseFeedQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.KnowledgeBaseFeedQuery, Types.KnowledgeBaseFeedQueryVariables>(KnowledgeBaseFeedDocument, options);
}
export function useKnowledgeBaseFeedLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.KnowledgeBaseFeedQuery, Types.KnowledgeBaseFeedQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.KnowledgeBaseFeedQuery, Types.KnowledgeBaseFeedQueryVariables>(KnowledgeBaseFeedDocument, options);
}
export type KnowledgeBaseFeedQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.KnowledgeBaseFeedQuery, Types.KnowledgeBaseFeedQueryVariables>;