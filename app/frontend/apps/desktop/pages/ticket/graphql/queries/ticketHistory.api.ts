import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { HistoryGroupFragmentDoc } from '../../../../../../shared/graphql/fragments/history.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketHistoryDocument = gql`
    query ticketHistory($ticketId: ID!) {
  ticketHistory(ticketId: $ticketId) {
    ...HistoryGroup
  }
}
    ${HistoryGroupFragmentDoc}`;
export function useTicketHistoryQuery(variables: Types.TicketHistoryQueryVariables | VueCompositionApi.Ref<Types.TicketHistoryQueryVariables> | ReactiveFunction<Types.TicketHistoryQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables>(TicketHistoryDocument, variables, options);
}
export function useTicketHistoryLazyQuery(variables?: Types.TicketHistoryQueryVariables | VueCompositionApi.Ref<Types.TicketHistoryQueryVariables> | ReactiveFunction<Types.TicketHistoryQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables>(TicketHistoryDocument, variables, options);
}
export type TicketHistoryQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables>;