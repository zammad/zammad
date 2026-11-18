import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { IdoitUpObjectAttributesFragmentDoc } from '../fragments/IdoitUpObjectAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketExternalReferencesIdoitUpObjectListDocument = gql`
    query ticketExternalReferencesIdoitUpObjectList($ticketId: ID, $idoitUpObjectIds: [String!]) {
  ticketExternalReferencesIdoitUpObjectList(
    input: { ticketId: $ticketId, idoitUpObjectIds: $idoitUpObjectIds }
  ) {
    ...IdoitUpObjectAttributes
  }
}
    ${IdoitUpObjectAttributesFragmentDoc}`;
export function useTicketExternalReferencesIdoitUpObjectListQuery(options: VueApolloComposable.useQuery.Options<Types.TicketExternalReferencesIdoitUpObjectListQuery, Types.TicketExternalReferencesIdoitUpObjectListQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.TicketExternalReferencesIdoitUpObjectListQuery, Types.TicketExternalReferencesIdoitUpObjectListQueryVariables>(TicketExternalReferencesIdoitUpObjectListDocument, options);
}
export function useTicketExternalReferencesIdoitUpObjectListLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketExternalReferencesIdoitUpObjectListQuery, Types.TicketExternalReferencesIdoitUpObjectListQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketExternalReferencesIdoitUpObjectListQuery, Types.TicketExternalReferencesIdoitUpObjectListQueryVariables>(TicketExternalReferencesIdoitUpObjectListDocument, options);
}
export type TicketExternalReferencesIdoitUpObjectListQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketExternalReferencesIdoitUpObjectListQuery, Types.TicketExternalReferencesIdoitUpObjectListQueryVariables>;