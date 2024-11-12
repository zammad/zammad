import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { IdoitObjectAttributesFragmentDoc } from '../fragments/IdoitObjectAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketExternalReferencesIdoitObjectSearchDocument = gql`
    query ticketExternalReferencesIdoitObjectSearch($idoitTypeId: String, $limit: Int!, $query: String) {
  ticketExternalReferencesIdoitObjectSearch(
    idoitTypeId: $idoitTypeId
    limit: $limit
    query: $query
  ) {
    ...IdoitObjectAttributes
  }
}
    ${IdoitObjectAttributesFragmentDoc}`;
export function useTicketExternalReferencesIdoitObjectSearchQuery(variables: Types.TicketExternalReferencesIdoitObjectSearchQueryVariables | VueCompositionApi.Ref<Types.TicketExternalReferencesIdoitObjectSearchQueryVariables> | ReactiveFunction<Types.TicketExternalReferencesIdoitObjectSearchQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesIdoitObjectSearchQuery, Types.TicketExternalReferencesIdoitObjectSearchQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesIdoitObjectSearchQuery, Types.TicketExternalReferencesIdoitObjectSearchQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesIdoitObjectSearchQuery, Types.TicketExternalReferencesIdoitObjectSearchQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketExternalReferencesIdoitObjectSearchQuery, Types.TicketExternalReferencesIdoitObjectSearchQueryVariables>(TicketExternalReferencesIdoitObjectSearchDocument, variables, options);
}
export function useTicketExternalReferencesIdoitObjectSearchLazyQuery(variables?: Types.TicketExternalReferencesIdoitObjectSearchQueryVariables | VueCompositionApi.Ref<Types.TicketExternalReferencesIdoitObjectSearchQueryVariables> | ReactiveFunction<Types.TicketExternalReferencesIdoitObjectSearchQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesIdoitObjectSearchQuery, Types.TicketExternalReferencesIdoitObjectSearchQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesIdoitObjectSearchQuery, Types.TicketExternalReferencesIdoitObjectSearchQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesIdoitObjectSearchQuery, Types.TicketExternalReferencesIdoitObjectSearchQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketExternalReferencesIdoitObjectSearchQuery, Types.TicketExternalReferencesIdoitObjectSearchQueryVariables>(TicketExternalReferencesIdoitObjectSearchDocument, variables, options);
}
export type TicketExternalReferencesIdoitObjectSearchQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketExternalReferencesIdoitObjectSearchQuery, Types.TicketExternalReferencesIdoitObjectSearchQueryVariables>;