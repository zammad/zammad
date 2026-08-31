import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { SimpleTicketAttributeFragmentDoc } from '../../../../../../shared/graphql/fragments/simpleTicketAttribute.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketsRecentlyViewedDocument = gql`
    query ticketsRecentlyViewed($limit: Int) {
  ticketsRecentlyViewed(limit: $limit) {
    ...simpleTicketAttribute
  }
}
    ${SimpleTicketAttributeFragmentDoc}`;
export function useTicketsRecentlyViewedQuery(variables: Types.TicketsRecentlyViewedQueryVariables | VueCompositionApi.Ref<Types.TicketsRecentlyViewedQueryVariables> | ReactiveFunction<Types.TicketsRecentlyViewedQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketsRecentlyViewedQuery, Types.TicketsRecentlyViewedQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsRecentlyViewedQuery, Types.TicketsRecentlyViewedQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsRecentlyViewedQuery, Types.TicketsRecentlyViewedQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketsRecentlyViewedQuery, Types.TicketsRecentlyViewedQueryVariables>(TicketsRecentlyViewedDocument, variables, options);
}
export function useTicketsRecentlyViewedLazyQuery(variables: Types.TicketsRecentlyViewedQueryVariables | VueCompositionApi.Ref<Types.TicketsRecentlyViewedQueryVariables> | ReactiveFunction<Types.TicketsRecentlyViewedQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketsRecentlyViewedQuery, Types.TicketsRecentlyViewedQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsRecentlyViewedQuery, Types.TicketsRecentlyViewedQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsRecentlyViewedQuery, Types.TicketsRecentlyViewedQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketsRecentlyViewedQuery, Types.TicketsRecentlyViewedQueryVariables>(TicketsRecentlyViewedDocument, variables, options);
}
export type TicketsRecentlyViewedQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketsRecentlyViewedQuery, Types.TicketsRecentlyViewedQueryVariables>;