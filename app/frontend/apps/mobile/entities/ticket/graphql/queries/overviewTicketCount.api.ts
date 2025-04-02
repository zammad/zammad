import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketOverviewTicketCountDocument = gql`
    query ticketOverviewTicketCount($ignoreUserConditions: Boolean!) {
  ticketOverviews(ignoreUserConditions: $ignoreUserConditions) {
    id
    ticketCount
  }
}
    `;
export function useTicketOverviewTicketCountQuery(variables: Types.TicketOverviewTicketCountQueryVariables | VueCompositionApi.Ref<Types.TicketOverviewTicketCountQueryVariables> | ReactiveFunction<Types.TicketOverviewTicketCountQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables>(TicketOverviewTicketCountDocument, variables, options);
}
export function useTicketOverviewTicketCountLazyQuery(variables?: Types.TicketOverviewTicketCountQueryVariables | VueCompositionApi.Ref<Types.TicketOverviewTicketCountQueryVariables> | ReactiveFunction<Types.TicketOverviewTicketCountQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables>(TicketOverviewTicketCountDocument, variables, options);
}
export type TicketOverviewTicketCountQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables>;