import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketsByFilterDocument = gql`
    query ticketsByFilter($customerId: ID, $stateTypeCategory: EnumTicketStateTypeCategory, $pageSize: Int = 7) {
  ticketsByFilter(
    customerId: $customerId
    stateTypeCategory: $stateTypeCategory
    first: $pageSize
  ) {
    totalCount
    edges {
      node {
        id
        internalId
        number
        title
        stateColorCode
        state {
          id
          name
        }
      }
    }
  }
}
    `;
export function useTicketsByFilterQuery(variables: Types.TicketsByFilterQueryVariables | VueCompositionApi.Ref<Types.TicketsByFilterQueryVariables> | ReactiveFunction<Types.TicketsByFilterQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketsByFilterQuery, Types.TicketsByFilterQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsByFilterQuery, Types.TicketsByFilterQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsByFilterQuery, Types.TicketsByFilterQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketsByFilterQuery, Types.TicketsByFilterQueryVariables>(TicketsByFilterDocument, variables, options);
}
export function useTicketsByFilterLazyQuery(variables: Types.TicketsByFilterQueryVariables | VueCompositionApi.Ref<Types.TicketsByFilterQueryVariables> | ReactiveFunction<Types.TicketsByFilterQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketsByFilterQuery, Types.TicketsByFilterQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsByFilterQuery, Types.TicketsByFilterQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsByFilterQuery, Types.TicketsByFilterQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketsByFilterQuery, Types.TicketsByFilterQueryVariables>(TicketsByFilterDocument, variables, options);
}
export type TicketsByFilterQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketsByFilterQuery, Types.TicketsByFilterQueryVariables>;