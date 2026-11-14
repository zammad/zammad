import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketArticleAttributesFragmentDoc } from '../../fragments/ticketArticleAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketArticlesDocument = gql`
    query ticketArticles($ticketId: ID!, $beforeCursor: String, $afterCursor: String, $pageSize: Int, $loadFirstArticles: Boolean = true, $firstArticlesCount: Int = 1) {
  firstArticles: ticketArticles(ticketId: $ticketId, first: $firstArticlesCount) @include(if: $loadFirstArticles) {
    edges {
      node {
        ...ticketArticleAttributes
      }
    }
  }
  articles: ticketArticles(
    ticketId: $ticketId
    before: $beforeCursor
    after: $afterCursor
    last: $pageSize
  ) {
    totalCount
    edges {
      node {
        ...ticketArticleAttributes
      }
      cursor
    }
    pageInfo {
      endCursor
      startCursor
      hasPreviousPage
    }
  }
}
    ${TicketArticleAttributesFragmentDoc}`;
export function useTicketArticlesQuery(options: VueApolloComposable.useQuery.Options<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables>(TicketArticlesDocument, options);
}
export function useTicketArticlesLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables>(TicketArticlesDocument, options);
}
export type TicketArticlesQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables>;