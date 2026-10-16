import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useTicketArticleQuotedHeaderQuery(variables: Types.TicketArticleQuotedHeaderQueryVariables | VueCompositionApi.Ref<Types.TicketArticleQuotedHeaderQueryVariables> | ReactiveFunction<Types.TicketArticleQuotedHeaderQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketArticleQuotedHeaderQuery, Types.TicketArticleQuotedHeaderQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketArticleQuotedHeaderQuery, Types.TicketArticleQuotedHeaderQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketArticleQuotedHeaderQuery, Types.TicketArticleQuotedHeaderQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketArticleQuotedHeaderQuery, Types.TicketArticleQuotedHeaderQueryVariables>(TicketArticleQuotedHeaderDocument, variables, options);
}
export function useTicketArticleQuotedHeaderLazyQuery(variables?: Types.TicketArticleQuotedHeaderQueryVariables | VueCompositionApi.Ref<Types.TicketArticleQuotedHeaderQueryVariables> | ReactiveFunction<Types.TicketArticleQuotedHeaderQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketArticleQuotedHeaderQuery, Types.TicketArticleQuotedHeaderQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketArticleQuotedHeaderQuery, Types.TicketArticleQuotedHeaderQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketArticleQuotedHeaderQuery, Types.TicketArticleQuotedHeaderQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketArticleQuotedHeaderQuery, Types.TicketArticleQuotedHeaderQueryVariables>(TicketArticleQuotedHeaderDocument, variables, options);
}
export type TicketArticleQuotedHeaderQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketArticleQuotedHeaderQuery, Types.TicketArticleQuotedHeaderQueryVariables>;