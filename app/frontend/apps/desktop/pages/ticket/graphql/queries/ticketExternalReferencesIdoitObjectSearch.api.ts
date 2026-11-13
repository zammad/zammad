import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { IdoitObjectAttributesFragmentDoc } from '../fragments/IdoitObjectAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useTicketExternalReferencesIdoitObjectSearchQuery(options: VueApolloComposable.useQuery.Options<Types.TicketExternalReferencesIdoitObjectSearchQuery, Types.TicketExternalReferencesIdoitObjectSearchQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketExternalReferencesIdoitObjectSearchQuery, Types.TicketExternalReferencesIdoitObjectSearchQueryVariables>(TicketExternalReferencesIdoitObjectSearchDocument, options);
}
export function useTicketExternalReferencesIdoitObjectSearchLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketExternalReferencesIdoitObjectSearchQuery, Types.TicketExternalReferencesIdoitObjectSearchQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketExternalReferencesIdoitObjectSearchQuery, Types.TicketExternalReferencesIdoitObjectSearchQueryVariables>(TicketExternalReferencesIdoitObjectSearchDocument, options);
}
export type TicketExternalReferencesIdoitObjectSearchQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketExternalReferencesIdoitObjectSearchQuery, Types.TicketExternalReferencesIdoitObjectSearchQueryVariables>;