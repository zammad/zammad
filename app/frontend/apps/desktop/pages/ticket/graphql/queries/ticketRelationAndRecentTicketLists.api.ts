import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { SimpleTicketAttributeFragmentDoc } from '../../../../../../shared/graphql/fragments/simpleTicketAttribute.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useTicketRelationAndRecentTicketListsQuery(variables: Types.TicketRelationAndRecentTicketListsQueryVariables | VueCompositionApi.Ref<Types.TicketRelationAndRecentTicketListsQueryVariables> | ReactiveFunction<Types.TicketRelationAndRecentTicketListsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketRelationAndRecentTicketListsQuery, Types.TicketRelationAndRecentTicketListsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketRelationAndRecentTicketListsQuery, Types.TicketRelationAndRecentTicketListsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketRelationAndRecentTicketListsQuery, Types.TicketRelationAndRecentTicketListsQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketRelationAndRecentTicketListsQuery, Types.TicketRelationAndRecentTicketListsQueryVariables>(TicketRelationAndRecentTicketListsDocument, variables, options);
}
export function useTicketRelationAndRecentTicketListsLazyQuery(variables?: Types.TicketRelationAndRecentTicketListsQueryVariables | VueCompositionApi.Ref<Types.TicketRelationAndRecentTicketListsQueryVariables> | ReactiveFunction<Types.TicketRelationAndRecentTicketListsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketRelationAndRecentTicketListsQuery, Types.TicketRelationAndRecentTicketListsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketRelationAndRecentTicketListsQuery, Types.TicketRelationAndRecentTicketListsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketRelationAndRecentTicketListsQuery, Types.TicketRelationAndRecentTicketListsQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketRelationAndRecentTicketListsQuery, Types.TicketRelationAndRecentTicketListsQueryVariables>(TicketRelationAndRecentTicketListsDocument, variables, options);
}
export type TicketRelationAndRecentTicketListsQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketRelationAndRecentTicketListsQuery, Types.TicketRelationAndRecentTicketListsQueryVariables>;