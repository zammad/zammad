import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketsByCustomerDocument = gql`
    query ticketsByCustomer($customerId: ID!, $customerOrganizations: Boolean, $stateTypeCategory: EnumTicketStateTypeCategory, $pageSize: Int = 7, $cursor: String) {
  ticketsByCustomer(
    customerId: $customerId
    customerOrganizations: $customerOrganizations
    stateTypeCategory: $stateTypeCategory
    first: $pageSize
    after: $cursor
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
        createdAt
      }
    }
    pageInfo {
      endCursor
    }
  }
}
    `;
export function useTicketsByCustomerQuery(variables: Types.TicketsByCustomerQueryVariables | VueCompositionApi.Ref<Types.TicketsByCustomerQueryVariables> | ReactiveFunction<Types.TicketsByCustomerQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketsByCustomerQuery, Types.TicketsByCustomerQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsByCustomerQuery, Types.TicketsByCustomerQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsByCustomerQuery, Types.TicketsByCustomerQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketsByCustomerQuery, Types.TicketsByCustomerQueryVariables>(TicketsByCustomerDocument, variables, options);
}
export function useTicketsByCustomerLazyQuery(variables?: Types.TicketsByCustomerQueryVariables | VueCompositionApi.Ref<Types.TicketsByCustomerQueryVariables> | ReactiveFunction<Types.TicketsByCustomerQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketsByCustomerQuery, Types.TicketsByCustomerQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsByCustomerQuery, Types.TicketsByCustomerQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsByCustomerQuery, Types.TicketsByCustomerQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketsByCustomerQuery, Types.TicketsByCustomerQueryVariables>(TicketsByCustomerDocument, variables, options);
}
export type TicketsByCustomerQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketsByCustomerQuery, Types.TicketsByCustomerQueryVariables>;