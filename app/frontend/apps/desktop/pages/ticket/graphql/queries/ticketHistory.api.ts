import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketHistoryDocument = gql`
    query ticketHistory($ticketId: ID, $ticketInternalId: Int, $ticketNumber: String) {
  ticketHistory(
    ticket: {ticketId: $ticketId, ticketInternalId: $ticketInternalId, ticketNumber: $ticketNumber}
  ) {
    createdAt
    records {
      issuer {
        ... on User {
          id
          internalId
          firstname
          lastname
          fullname
          phone
          email
          image
        }
        ... on Trigger {
          id
          name
        }
        ... on Job {
          id
          name
        }
        ... on PostmasterFilter {
          id
          name
        }
        ... on ObjectClass {
          klass
          info
        }
      }
      events {
        createdAt
        action
        object {
          ... on Checklist {
            id
            name
          }
          ... on ChecklistItem {
            id
            text
            checked
          }
          ... on Group {
            id
            name
          }
          ... on Mention {
            id
            user {
              id
              fullname
            }
          }
          ... on Organization {
            id
            name
          }
          ... on Ticket {
            id
            internalId
            number
            title
          }
          ... on TicketArticle {
            id
            body
          }
          ... on TicketSharedDraftZoom {
            id
          }
          ... on User {
            id
            fullname
          }
          ... on ObjectClass {
            klass
            info
          }
        }
        attribute
        changes
      }
    }
  }
}
    `;
export function useTicketHistoryQuery(variables: Types.TicketHistoryQueryVariables | VueCompositionApi.Ref<Types.TicketHistoryQueryVariables> | ReactiveFunction<Types.TicketHistoryQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables>(TicketHistoryDocument, variables, options);
}
export function useTicketHistoryLazyQuery(variables: Types.TicketHistoryQueryVariables | VueCompositionApi.Ref<Types.TicketHistoryQueryVariables> | ReactiveFunction<Types.TicketHistoryQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables>(TicketHistoryDocument, variables, options);
}
export type TicketHistoryQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketHistoryQuery, Types.TicketHistoryQueryVariables>;