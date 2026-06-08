import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useTicketsStatsMonthlyByCustomerQuery(variables: Types.TicketsStatsMonthlyByCustomerQueryVariables | VueCompositionApi.Ref<Types.TicketsStatsMonthlyByCustomerQueryVariables> | ReactiveFunction<Types.TicketsStatsMonthlyByCustomerQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketsStatsMonthlyByCustomerQuery, Types.TicketsStatsMonthlyByCustomerQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsStatsMonthlyByCustomerQuery, Types.TicketsStatsMonthlyByCustomerQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsStatsMonthlyByCustomerQuery, Types.TicketsStatsMonthlyByCustomerQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketsStatsMonthlyByCustomerQuery, Types.TicketsStatsMonthlyByCustomerQueryVariables>(TicketsStatsMonthlyByCustomerDocument, variables, options);
}
export function useTicketsStatsMonthlyByCustomerLazyQuery(variables?: Types.TicketsStatsMonthlyByCustomerQueryVariables | VueCompositionApi.Ref<Types.TicketsStatsMonthlyByCustomerQueryVariables> | ReactiveFunction<Types.TicketsStatsMonthlyByCustomerQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketsStatsMonthlyByCustomerQuery, Types.TicketsStatsMonthlyByCustomerQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsStatsMonthlyByCustomerQuery, Types.TicketsStatsMonthlyByCustomerQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsStatsMonthlyByCustomerQuery, Types.TicketsStatsMonthlyByCustomerQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketsStatsMonthlyByCustomerQuery, Types.TicketsStatsMonthlyByCustomerQueryVariables>(TicketsStatsMonthlyByCustomerDocument, variables, options);
}
export type TicketsStatsMonthlyByCustomerQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketsStatsMonthlyByCustomerQuery, Types.TicketsStatsMonthlyByCustomerQueryVariables>;