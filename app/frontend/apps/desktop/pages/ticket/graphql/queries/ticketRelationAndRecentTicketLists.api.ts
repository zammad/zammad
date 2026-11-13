import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { SimpleTicketAttributeFragmentDoc } from '../../../../../../shared/graphql/fragments/simpleTicketAttribute.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketRelationAndRecentTicketListsDocument = gql`
    query ticketRelationAndRecentTicketLists($ticketId: Int!, $customerId: ID!, $limit: Int) {
  ticketsRecentByCustomer(
    customerId: $customerId
    limit: $limit
    exceptTicketInternalId: $ticketId
  ) {
    ...simpleTicketAttribute
  }
  ticketsRecentlyViewed(exceptTicketInternalId: $ticketId, limit: $limit) {
    ...simpleTicketAttribute
  }
}
    ${SimpleTicketAttributeFragmentDoc}`;
export function useTicketRelationAndRecentTicketListsQuery(options: VueApolloComposable.useQuery.Options<Types.TicketRelationAndRecentTicketListsQuery, Types.TicketRelationAndRecentTicketListsQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketRelationAndRecentTicketListsQuery, Types.TicketRelationAndRecentTicketListsQueryVariables>(TicketRelationAndRecentTicketListsDocument, options);
}
export function useTicketRelationAndRecentTicketListsLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketRelationAndRecentTicketListsQuery, Types.TicketRelationAndRecentTicketListsQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketRelationAndRecentTicketListsQuery, Types.TicketRelationAndRecentTicketListsQueryVariables>(TicketRelationAndRecentTicketListsDocument, options);
}
export type TicketRelationAndRecentTicketListsQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketRelationAndRecentTicketListsQuery, Types.TicketRelationAndRecentTicketListsQueryVariables>;