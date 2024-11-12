import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { IdoitObjectAttributesFragmentDoc } from '../fragments/IdoitObjectAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketExternalReferencesIdoitObjectListDocument = gql`
    query ticketExternalReferencesIdoitObjectList($ticketId: ID, $idoitObjectIds: [Int!]) {
  ticketExternalReferencesIdoitObjectList(
    input: {ticketId: $ticketId, idoitObjectIds: $idoitObjectIds}
  ) {
    ...IdoitObjectAttributes
  }
}
    ${IdoitObjectAttributesFragmentDoc}`;
export function useTicketExternalReferencesIdoitObjectListQuery(variables: Types.TicketExternalReferencesIdoitObjectListQueryVariables | VueCompositionApi.Ref<Types.TicketExternalReferencesIdoitObjectListQueryVariables> | ReactiveFunction<Types.TicketExternalReferencesIdoitObjectListQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesIdoitObjectListQuery, Types.TicketExternalReferencesIdoitObjectListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesIdoitObjectListQuery, Types.TicketExternalReferencesIdoitObjectListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesIdoitObjectListQuery, Types.TicketExternalReferencesIdoitObjectListQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketExternalReferencesIdoitObjectListQuery, Types.TicketExternalReferencesIdoitObjectListQueryVariables>(TicketExternalReferencesIdoitObjectListDocument, variables, options);
}
export function useTicketExternalReferencesIdoitObjectListLazyQuery(variables: Types.TicketExternalReferencesIdoitObjectListQueryVariables | VueCompositionApi.Ref<Types.TicketExternalReferencesIdoitObjectListQueryVariables> | ReactiveFunction<Types.TicketExternalReferencesIdoitObjectListQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesIdoitObjectListQuery, Types.TicketExternalReferencesIdoitObjectListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesIdoitObjectListQuery, Types.TicketExternalReferencesIdoitObjectListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesIdoitObjectListQuery, Types.TicketExternalReferencesIdoitObjectListQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketExternalReferencesIdoitObjectListQuery, Types.TicketExternalReferencesIdoitObjectListQueryVariables>(TicketExternalReferencesIdoitObjectListDocument, variables, options);
}
export type TicketExternalReferencesIdoitObjectListQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketExternalReferencesIdoitObjectListQuery, Types.TicketExternalReferencesIdoitObjectListQueryVariables>;