import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { SimpleTicketAttributeFragmentDoc } from '../../../../../shared/graphql/fragments/simpleTicketAttribute.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TodaysTicketsDocument = gql`
    query todaysTickets {
  todaysTickets {
    totalCount
    edges {
      node {
        ...simpleTicketAttribute
      }
    }
  }
}
    ${SimpleTicketAttributeFragmentDoc}`;


export function useTodaysTicketsQuery(options: VueApolloComposable.UseQueryOptions<TodaysTicketsQuery, TodaysTicketsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<TodaysTicketsQuery, TodaysTicketsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<TodaysTicketsQuery, TodaysTicketsQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<TodaysTicketsQuery, TodaysTicketsQueryVariables>(TodaysTicketsDocument, {}, options);
}


export function useTodaysTicketsLazyQuery(options: VueApolloComposable.UseLazyQueryOptions<TodaysTicketsQuery, TodaysTicketsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseLazyQueryOptions<TodaysTicketsQuery, TodaysTicketsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseLazyQueryOptions<TodaysTicketsQuery, TodaysTicketsQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<TodaysTicketsQuery, TodaysTicketsQueryVariables>(TodaysTicketsDocument, {}, options);
}

export type TodaysTicketsQueryVariables = Types.Exact<{ [key: string]: never; }>;


export type TodaysTicketsQuery = { __typename?: 'Queries', todaysTickets?: { __typename?: 'TicketConnection', totalCount: number, edges: Array<{ __typename?: 'TicketEdge', node: { __typename?: 'Ticket', id: string, internalId: number, number: string, title: string, createdAt: string, stateColorCode: Types.EnumTicketStateColorCode, customer?: { __typename?: 'User', id: string, internalId: number, fullname: string } | null, organization?: { __typename?: 'Organization', id: string, internalId: number, name: string } | null, group: { __typename?: 'Group', id: string, name: string }, state: { __typename?: 'TicketState', id: string, name: string } } }> } | null };
