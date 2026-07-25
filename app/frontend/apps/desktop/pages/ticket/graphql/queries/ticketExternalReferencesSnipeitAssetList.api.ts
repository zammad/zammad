import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { SnipeitAssetAttributesFragmentDoc } from '../fragments/SnipeitAssetAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketExternalReferencesSnipeitAssetListDocument = gql`
    query ticketExternalReferencesSnipeitAssetList($ticketId: ID, $snipeitAssetIds: [Int!]) {
  ticketExternalReferencesSnipeitAssetList(
    input: {ticketId: $ticketId, snipeitAssetIds: $snipeitAssetIds}
  ) {
    ...SnipeitAssetAttributes
  }
}
    ${SnipeitAssetAttributesFragmentDoc}`;
export function useTicketExternalReferencesSnipeitAssetListQuery(variables: Types.TicketExternalReferencesSnipeitAssetListQueryVariables | VueCompositionApi.Ref<Types.TicketExternalReferencesSnipeitAssetListQueryVariables> | ReactiveFunction<Types.TicketExternalReferencesSnipeitAssetListQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesSnipeitAssetListQuery, Types.TicketExternalReferencesSnipeitAssetListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesSnipeitAssetListQuery, Types.TicketExternalReferencesSnipeitAssetListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesSnipeitAssetListQuery, Types.TicketExternalReferencesSnipeitAssetListQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketExternalReferencesSnipeitAssetListQuery, Types.TicketExternalReferencesSnipeitAssetListQueryVariables>(TicketExternalReferencesSnipeitAssetListDocument, variables, options);
}
export function useTicketExternalReferencesSnipeitAssetListLazyQuery(variables: Types.TicketExternalReferencesSnipeitAssetListQueryVariables | VueCompositionApi.Ref<Types.TicketExternalReferencesSnipeitAssetListQueryVariables> | ReactiveFunction<Types.TicketExternalReferencesSnipeitAssetListQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesSnipeitAssetListQuery, Types.TicketExternalReferencesSnipeitAssetListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesSnipeitAssetListQuery, Types.TicketExternalReferencesSnipeitAssetListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketExternalReferencesSnipeitAssetListQuery, Types.TicketExternalReferencesSnipeitAssetListQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketExternalReferencesSnipeitAssetListQuery, Types.TicketExternalReferencesSnipeitAssetListQueryVariables>(TicketExternalReferencesSnipeitAssetListDocument, variables, options);
}
export type TicketExternalReferencesSnipeitAssetListQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketExternalReferencesSnipeitAssetListQuery, Types.TicketExternalReferencesSnipeitAssetListQueryVariables>;
