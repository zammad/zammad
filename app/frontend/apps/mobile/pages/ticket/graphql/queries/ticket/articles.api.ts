import * as Types from '../../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import { TicketArticleAttributesFragmentDoc } from '../../fragments/ticketArticleAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketArticlesDocument = gql`
    query ticketArticles($ticketId: ID, $ticketInternalId: Int, $ticketNumber: String, $beforeCursor: String, $afterCursor: String, $pageSize: Int, $loadDescription: Boolean = true) {
  description: ticketArticles(
    ticket: {ticketId: $ticketId, ticketInternalId: $ticketInternalId, ticketNumber: $ticketNumber}
    first: 1
  ) @include(if: $loadDescription) {
    edges {
      node {
        ...ticketArticleAttributes
      }
    }
  }
  articles: ticketArticles(
    ticket: {ticketId: $ticketId, ticketInternalId: $ticketInternalId, ticketNumber: $ticketNumber}
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
export function useTicketArticlesQuery(variables: Types.TicketArticlesQueryVariables | VueCompositionApi.Ref<Types.TicketArticlesQueryVariables> | ReactiveFunction<Types.TicketArticlesQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables>(TicketArticlesDocument, variables, options);
}
export function useTicketArticlesLazyQuery(variables: Types.TicketArticlesQueryVariables | VueCompositionApi.Ref<Types.TicketArticlesQueryVariables> | ReactiveFunction<Types.TicketArticlesQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables>(TicketArticlesDocument, variables, options);
}
export type TicketArticlesQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables>;