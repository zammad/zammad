import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { OverviewAttributesFragmentDoc } from '../../../../../../shared/entities/ticket/graphql/fragments/overviewAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketOverviewOrderDocument = gql`
    query ticketOverviewOrder($withTicketCount: Boolean = false) {
  ticketOverviews(ignoreUserConditions: true) {
    ...overviewAttributes
    viewColumns {
      key
      value
    }
    orderColumns {
      key
      value
    }
  }
}
    ${OverviewAttributesFragmentDoc}`;
export function useTicketOverviewOrderQuery(variables: Types.TicketOverviewOrderQueryVariables | VueCompositionApi.Ref<Types.TicketOverviewOrderQueryVariables> | ReactiveFunction<Types.TicketOverviewOrderQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketOverviewOrderQuery, Types.TicketOverviewOrderQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketOverviewOrderQuery, Types.TicketOverviewOrderQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketOverviewOrderQuery, Types.TicketOverviewOrderQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketOverviewOrderQuery, Types.TicketOverviewOrderQueryVariables>(TicketOverviewOrderDocument, variables, options);
}
export function useTicketOverviewOrderLazyQuery(variables: Types.TicketOverviewOrderQueryVariables | VueCompositionApi.Ref<Types.TicketOverviewOrderQueryVariables> | ReactiveFunction<Types.TicketOverviewOrderQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketOverviewOrderQuery, Types.TicketOverviewOrderQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketOverviewOrderQuery, Types.TicketOverviewOrderQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketOverviewOrderQuery, Types.TicketOverviewOrderQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketOverviewOrderQuery, Types.TicketOverviewOrderQueryVariables>(TicketOverviewOrderDocument, variables, options);
}
export type TicketOverviewOrderQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketOverviewOrderQuery, Types.TicketOverviewOrderQueryVariables>;