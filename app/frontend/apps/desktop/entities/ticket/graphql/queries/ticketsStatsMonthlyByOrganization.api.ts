import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketsStatsMonthlyByOrganizationDocument = gql`
    query TicketsStatsMonthlyByOrganization($organizationId: ID!) {
  ticketsStatsMonthlyByOrganization(organizationId: $organizationId) {
    monthLabel
    monthNumber
    ticketsClosed
    ticketsCreated
    year
  }
}
    `;
export function useTicketsStatsMonthlyByOrganizationQuery(options: VueApolloComposable.useQuery.Options<Types.TicketsStatsMonthlyByOrganizationQuery, Types.TicketsStatsMonthlyByOrganizationQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketsStatsMonthlyByOrganizationQuery, Types.TicketsStatsMonthlyByOrganizationQueryVariables>(TicketsStatsMonthlyByOrganizationDocument, options);
}
export function useTicketsStatsMonthlyByOrganizationLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketsStatsMonthlyByOrganizationQuery, Types.TicketsStatsMonthlyByOrganizationQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketsStatsMonthlyByOrganizationQuery, Types.TicketsStatsMonthlyByOrganizationQueryVariables>(TicketsStatsMonthlyByOrganizationDocument, options);
}
export type TicketsStatsMonthlyByOrganizationQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketsStatsMonthlyByOrganizationQuery, Types.TicketsStatsMonthlyByOrganizationQueryVariables>;