import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketArticleQuotedHeaderDocument = gql`
    query ticketArticleQuotedHeader($articleId: ID!) {
  ticketArticleQuotedHeader(articleId: $articleId) {
    from
    to
    cc
    authorName
  }
}
    `;
export function useTicketArticleQuotedHeaderQuery(options: VueApolloComposable.useQuery.Options<Types.TicketArticleQuotedHeaderQuery, Types.TicketArticleQuotedHeaderQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketArticleQuotedHeaderQuery, Types.TicketArticleQuotedHeaderQueryVariables>(TicketArticleQuotedHeaderDocument, options);
}
export function useTicketArticleQuotedHeaderLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketArticleQuotedHeaderQuery, Types.TicketArticleQuotedHeaderQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketArticleQuotedHeaderQuery, Types.TicketArticleQuotedHeaderQueryVariables>(TicketArticleQuotedHeaderDocument, options);
}
export type TicketArticleQuotedHeaderQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketArticleQuotedHeaderQuery, Types.TicketArticleQuotedHeaderQueryVariables>;