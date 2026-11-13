import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketsStatsMonthlyByCustomerDocument = gql`
    query TicketsStatsMonthlyByCustomer($customerId: ID!) {
  ticketsStatsMonthlyByCustomer(customerId: $customerId) {
    monthLabel
    monthNumber
    ticketsClosed
    ticketsCreated
    year
  }
}
    `;
export function useTicketsStatsMonthlyByCustomerQuery(options: VueApolloComposable.useQuery.Options<Types.TicketsStatsMonthlyByCustomerQuery, Types.TicketsStatsMonthlyByCustomerQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketsStatsMonthlyByCustomerQuery, Types.TicketsStatsMonthlyByCustomerQueryVariables>(TicketsStatsMonthlyByCustomerDocument, options);
}
export function useTicketsStatsMonthlyByCustomerLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketsStatsMonthlyByCustomerQuery, Types.TicketsStatsMonthlyByCustomerQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketsStatsMonthlyByCustomerQuery, Types.TicketsStatsMonthlyByCustomerQueryVariables>(TicketsStatsMonthlyByCustomerDocument, options);
}
export type TicketsStatsMonthlyByCustomerQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketsStatsMonthlyByCustomerQuery, Types.TicketsStatsMonthlyByCustomerQueryVariables>;