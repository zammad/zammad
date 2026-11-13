import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useTicketsByCustomerQuery(options: VueApolloComposable.useQuery.Options<Types.TicketsByCustomerQuery, Types.TicketsByCustomerQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketsByCustomerQuery, Types.TicketsByCustomerQueryVariables>(TicketsByCustomerDocument, options);
}
export function useTicketsByCustomerLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketsByCustomerQuery, Types.TicketsByCustomerQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketsByCustomerQuery, Types.TicketsByCustomerQueryVariables>(TicketsByCustomerDocument, options);
}
export type TicketsByCustomerQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketsByCustomerQuery, Types.TicketsByCustomerQueryVariables>;