import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { IdoitUpObjectAttributesFragmentDoc } from '../fragments/IdoitUpObjectAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketExternalReferencesIdoitUpObjectSearchDocument = gql`
    query ticketExternalReferencesIdoitUpObjectSearch($idoitUpTypeId: String, $limit: Int!, $query: String) {
  ticketExternalReferencesIdoitUpObjectSearch(
    idoitUpTypeId: $idoitUpTypeId
    limit: $limit
    query: $query
  ) {
    ...IdoitUpObjectAttributes
  }
}
    ${IdoitUpObjectAttributesFragmentDoc}`;
export function useTicketExternalReferencesIdoitUpObjectSearchQuery(options: VueApolloComposable.useQuery.Options<Types.TicketExternalReferencesIdoitUpObjectSearchQuery, Types.TicketExternalReferencesIdoitUpObjectSearchQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketExternalReferencesIdoitUpObjectSearchQuery, Types.TicketExternalReferencesIdoitUpObjectSearchQueryVariables>(TicketExternalReferencesIdoitUpObjectSearchDocument, options);
}
export function useTicketExternalReferencesIdoitUpObjectSearchLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketExternalReferencesIdoitUpObjectSearchQuery, Types.TicketExternalReferencesIdoitUpObjectSearchQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketExternalReferencesIdoitUpObjectSearchQuery, Types.TicketExternalReferencesIdoitUpObjectSearchQueryVariables>(TicketExternalReferencesIdoitUpObjectSearchDocument, options);
}
export type TicketExternalReferencesIdoitUpObjectSearchQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketExternalReferencesIdoitUpObjectSearchQuery, Types.TicketExternalReferencesIdoitUpObjectSearchQueryVariables>;