import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { HistoryEventObjectFragmentDoc, HistoryEventFragmentDoc, HistoryIssuerFragmentDoc, HistoryGroupFragmentDoc } from '../../../../../../shared/graphql/fragments/history.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketHistoryDocument = gql`
    query ticketHistory($ticketId: ID!) {
  ticketHistory(ticketId: $ticketId) {
    ...HistoryGroup
  }
}
    ${HistoryGroupFragmentDoc}
${HistoryIssuerFragmentDoc}
${HistoryEventFragmentDoc}
${HistoryEventObjectFragmentDoc}`;
export function useTicketHistoryQuery(options: VueApolloComposable.useQuery.Options<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables>(TicketHistoryDocument, options);
}
export function useTicketHistoryLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables>(TicketHistoryDocument, options);
}
export type TicketHistoryQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables>;