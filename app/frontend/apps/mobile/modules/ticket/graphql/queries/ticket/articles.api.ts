import * as Types from '../../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketArticlesDocument = gql`
    query ticketArticles($ticketId: ID, $ticketInternalId: Int, $ticketNumber: String, $isAgent: Boolean!) {
  ticketArticles(
    ticket: {ticketId: $ticketId, ticketInternalId: $ticketInternalId, ticketNumber: $ticketNumber}
  ) {
    totalCount
    edges {
      node {
        id
        internalId
        from {
          raw
          parsed {
            name
            emailAddress
          }
        }
        to {
          raw
          parsed {
            name
            emailAddress
          }
        }
        cc {
          raw
          parsed {
            name
            emailAddress
          }
        }
        subject
        replyTo {
          raw
          parsed {
            name
            emailAddress
          }
        }
        messageId
        messageIdMd5
        inReplyTo
        contentType
        references
        attachments {
          internalId
          name
          size
          type
          preferences
        }
        preferences
        body
        internal
        createdAt
        createdBy @include(if: $isAgent) {
          id
          firstname
          lastname
        }
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