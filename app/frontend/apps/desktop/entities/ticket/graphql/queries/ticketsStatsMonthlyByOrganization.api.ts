import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useTicketsStatsMonthlyByOrganizationQuery(variables: Types.TicketsStatsMonthlyByOrganizationQueryVariables | VueCompositionApi.Ref<Types.TicketsStatsMonthlyByOrganizationQueryVariables> | ReactiveFunction<Types.TicketsStatsMonthlyByOrganizationQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketsStatsMonthlyByOrganizationQuery, Types.TicketsStatsMonthlyByOrganizationQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsStatsMonthlyByOrganizationQuery, Types.TicketsStatsMonthlyByOrganizationQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsStatsMonthlyByOrganizationQuery, Types.TicketsStatsMonthlyByOrganizationQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketsStatsMonthlyByOrganizationQuery, Types.TicketsStatsMonthlyByOrganizationQueryVariables>(TicketsStatsMonthlyByOrganizationDocument, variables, options);
}
export function useTicketsStatsMonthlyByOrganizationLazyQuery(variables?: Types.TicketsStatsMonthlyByOrganizationQueryVariables | VueCompositionApi.Ref<Types.TicketsStatsMonthlyByOrganizationQueryVariables> | ReactiveFunction<Types.TicketsStatsMonthlyByOrganizationQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketsStatsMonthlyByOrganizationQuery, Types.TicketsStatsMonthlyByOrganizationQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsStatsMonthlyByOrganizationQuery, Types.TicketsStatsMonthlyByOrganizationQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsStatsMonthlyByOrganizationQuery, Types.TicketsStatsMonthlyByOrganizationQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketsStatsMonthlyByOrganizationQuery, Types.TicketsStatsMonthlyByOrganizationQueryVariables>(TicketsStatsMonthlyByOrganizationDocument, variables, options);
}
export type TicketsStatsMonthlyByOrganizationQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketsStatsMonthlyByOrganizationQuery, Types.TicketsStatsMonthlyByOrganizationQueryVariables>;