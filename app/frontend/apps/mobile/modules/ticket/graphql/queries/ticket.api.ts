import * as Types from '../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import { ObjectAttributeValuesFragmentDoc } from '../../../../../../shared/graphql/fragments/objectAttributeValues.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketDocument = gql`
    query ticket($ticketId: ID, $ticketInternalId: Int, $ticketNumber: String, $withArticles: Boolean = false, $withObjectAttributes: Boolean = false) {
  ticket(
    ticket: {ticketId: $ticketId, ticketInternalId: $ticketInternalId, ticketNumber: $ticketNumber}
  ) {
    id
    internalId
    number
    title
    createdAt
    updatedAt
    owner {
      firstname
      lastname
    }
    customer {
      firstname
      lastname
    }
    organization {
      name
    }
    state {
      name
      stateType {
        name
      }
    }
    group {
      name
    }
    priority {
      name
    }
    articles @include(if: $withArticles) {
      edges {
        node {
          subject
        }
      }
    }
    objectAttributeValues @include(if: $withObjectAttributes) {
      ...objectAttributeValues
    }
  }
}
    ${ObjectAttributeValuesFragmentDoc}`;
export function useTicketQuery(variables: Types.TicketQueryVariables | VueCompositionApi.Ref<Types.TicketQueryVariables> | ReactiveFunction<Types.TicketQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketQuery, Types.TicketQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketQuery, Types.TicketQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketQuery, Types.TicketQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketQuery, Types.TicketQueryVariables>(TicketDocument, variables, options);
}
export function useTicketLazyQuery(variables: Types.TicketQueryVariables | VueCompositionApi.Ref<Types.TicketQueryVariables> | ReactiveFunction<Types.TicketQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketQuery, Types.TicketQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketQuery, Types.TicketQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketQuery, Types.TicketQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketQuery, Types.TicketQueryVariables>(TicketDocument, variables, options);
}
export type TicketQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketQuery, Types.TicketQueryVariables>;