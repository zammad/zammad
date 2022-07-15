import * as Types from '../../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketArticlesDocument = gql`
    query ticketArticles($ticketId: ID!) {
  ticketArticles(ticketId: $ticketId) {
    totalCount
    edges {
      node {
        id
        from
        to
        cc
        subject
        replyTo
        messageId
        messageIdMd5
        inReplyTo
        contentType
        references
        body
        internal
        createdAt
        updatedAt
        type {
          name
        }
        sender {
          name
        }
      }
      cursor
    }
    pageInfo {
      endCursor
      hasNextPage
    }
  }
}
    `;
export function useTicketArticlesQuery(variables: Types.TicketArticlesQueryVariables | VueCompositionApi.Ref<Types.TicketArticlesQueryVariables> | ReactiveFunction<Types.TicketArticlesQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables>(TicketArticlesDocument, variables, options);
}
export function useTicketArticlesLazyQuery(variables: Types.TicketArticlesQueryVariables | VueCompositionApi.Ref<Types.TicketArticlesQueryVariables> | ReactiveFunction<Types.TicketArticlesQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables>(TicketArticlesDocument, variables, options);
}
export type TicketArticlesQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables>;