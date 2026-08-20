import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseFeedAttributesFragmentDoc } from '../fragments/knowledgeBaseFeedAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const KnowledgeBaseFeedDocument = gql`
    query knowledgeBaseFeed($categoryId: ID, $locale: String) {
  knowledgeBaseFeed(categoryId: $categoryId, locale: $locale) {
    ...knowledgeBaseFeedAttributes
  }
}
    ${KnowledgeBaseFeedAttributesFragmentDoc}`;
export function useKnowledgeBaseFeedQuery(variables: Types.KnowledgeBaseFeedQueryVariables | VueCompositionApi.Ref<Types.KnowledgeBaseFeedQueryVariables> | ReactiveFunction<Types.KnowledgeBaseFeedQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseFeedQuery, Types.KnowledgeBaseFeedQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseFeedQuery, Types.KnowledgeBaseFeedQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseFeedQuery, Types.KnowledgeBaseFeedQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.KnowledgeBaseFeedQuery, Types.KnowledgeBaseFeedQueryVariables>(KnowledgeBaseFeedDocument, variables, options);
}
export function useKnowledgeBaseFeedLazyQuery(variables: Types.KnowledgeBaseFeedQueryVariables | VueCompositionApi.Ref<Types.KnowledgeBaseFeedQueryVariables> | ReactiveFunction<Types.KnowledgeBaseFeedQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseFeedQuery, Types.KnowledgeBaseFeedQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseFeedQuery, Types.KnowledgeBaseFeedQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseFeedQuery, Types.KnowledgeBaseFeedQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.KnowledgeBaseFeedQuery, Types.KnowledgeBaseFeedQueryVariables>(KnowledgeBaseFeedDocument, variables, options);
}
export type KnowledgeBaseFeedQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.KnowledgeBaseFeedQuery, Types.KnowledgeBaseFeedQueryVariables>;