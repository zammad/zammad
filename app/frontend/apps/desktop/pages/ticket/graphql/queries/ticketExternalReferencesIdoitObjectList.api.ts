import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { IdoitObjectAttributesFragmentDoc } from '../fragments/IdoitObjectAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketExternalReferencesIdoitObjectListDocument = gql`
    query ticketExternalReferencesIdoitObjectList($ticketId: ID, $idoitObjectIds: [Int!]) {
  ticketExternalReferencesIdoitObjectList(
    input: { ticketId: $ticketId, idoitObjectIds: $idoitObjectIds }
  ) {
    ...IdoitObjectAttributes
  }
}
    ${IdoitObjectAttributesFragmentDoc}`;
export function useTicketExternalReferencesIdoitObjectListQuery(options: VueApolloComposable.useQuery.Options<Types.TicketExternalReferencesIdoitObjectListQuery, Types.TicketExternalReferencesIdoitObjectListQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.TicketExternalReferencesIdoitObjectListQuery, Types.TicketExternalReferencesIdoitObjectListQueryVariables>(TicketExternalReferencesIdoitObjectListDocument, options);
}
export function useTicketExternalReferencesIdoitObjectListLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketExternalReferencesIdoitObjectListQuery, Types.TicketExternalReferencesIdoitObjectListQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketExternalReferencesIdoitObjectListQuery, Types.TicketExternalReferencesIdoitObjectListQueryVariables>(TicketExternalReferencesIdoitObjectListDocument, options);
}
export type TicketExternalReferencesIdoitObjectListQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketExternalReferencesIdoitObjectListQuery, Types.TicketExternalReferencesIdoitObjectListQueryVariables>;