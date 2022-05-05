import * as Types from '../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import { ObjectAttributeValuesFragmentDoc } from '../../../../../../shared/graphql/fragments/objectAttributeValues.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketsByIdDocument = gql`
    query ticketsById($ticketId: ID!, $withArticles: Boolean = false, $withObjectAttributes: Boolean = false) {
  ticketById(ticketId: $ticketId) {
    id
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
export function useTicketsByIdQuery(variables: Types.TicketsByIdQueryVariables | VueCompositionApi.Ref<Types.TicketsByIdQueryVariables> | ReactiveFunction<Types.TicketsByIdQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketsByIdQuery, Types.TicketsByIdQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsByIdQuery, Types.TicketsByIdQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsByIdQuery, Types.TicketsByIdQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketsByIdQuery, Types.TicketsByIdQueryVariables>(TicketsByIdDocument, variables, options);
}
export function useTicketsByIdLazyQuery(variables: Types.TicketsByIdQueryVariables | VueCompositionApi.Ref<Types.TicketsByIdQueryVariables> | ReactiveFunction<Types.TicketsByIdQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketsByIdQuery, Types.TicketsByIdQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketsByIdQuery, Types.TicketsByIdQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketsByIdQuery, Types.TicketsByIdQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketsByIdQuery, Types.TicketsByIdQueryVariables>(TicketsByIdDocument, variables, options);
}
export type TicketsByIdQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketsByIdQuery, Types.TicketsByIdQueryVariables>;