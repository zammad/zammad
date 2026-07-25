import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { SnipeitAssetAttributesFragmentDoc } from '../fragments/SnipeitAssetAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketExternalReferencesSnipeitAssetSearchDocument = gql`
    query ticketExternalReferencesSnipeitAssetSearch($categoryId: String, $modelId: String, $limit: Int!, $query: String) {
  ticketExternalReferencesSnipeitAssetSearch(
    categoryId: $categoryId
    modelId: $modelId
    limit: $limit
    query: $query
  ) {
    ...SnipeitAssetAttributes
  }
}
    ${SnipeitAssetAttributesFragmentDoc}`;
export function useTicketExternalReferencesSnipeitAssetSearchQuery(variables: Types.TicketExternalReferencesSnipeitAssetSearchQueryVariables | VueCompositionApi.Ref<Types.TicketExternalReferencesSnipeitAssetSearchQueryVariables> | ReactiveFunction<Types.TicketExternalReferencesSnipeitAssetSearchQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesSnipeitAssetSearchQuery, Types.TicketExternalReferencesSnipeitAssetSearchQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesSnipeitAssetSearchQuery, Types.TicketExternalReferencesSnipeitAssetSearchQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesSnipeitAssetSearchQuery, Types.TicketExternalReferencesSnipeitAssetSearchQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketExternalReferencesSnipeitAssetSearchQuery, Types.TicketExternalReferencesSnipeitAssetSearchQueryVariables>(TicketExternalReferencesSnipeitAssetSearchDocument, variables, options);
}
export function useTicketExternalReferencesSnipeitAssetSearchLazyQuery(variables?: Types.TicketExternalReferencesSnipeitAssetSearchQueryVariables | VueCompositionApi.Ref<Types.TicketExternalReferencesSnipeitAssetSearchQueryVariables> | ReactiveFunction<Types.TicketExternalReferencesSnipeitAssetSearchQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesSnipeitAssetSearchQuery, Types.TicketExternalReferencesSnipeitAssetSearchQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesSnipeitAssetSearchQuery, Types.TicketExternalReferencesSnipeitAssetSearchQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesSnipeitAssetSearchQuery, Types.TicketExternalReferencesSnipeitAssetSearchQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketExternalReferencesSnipeitAssetSearchQuery, Types.TicketExternalReferencesSnipeitAssetSearchQueryVariables>(TicketExternalReferencesSnipeitAssetSearchDocument, variables, options);
}
export type TicketExternalReferencesSnipeitAssetSearchQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketExternalReferencesSnipeitAssetSearchQuery, Types.TicketExternalReferencesSnipeitAssetSearchQueryVariables>;
