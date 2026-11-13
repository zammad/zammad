import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketPopoverArticleFragmentDoc } from '../fragments/ticketPopoverArticle.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketInfoForPopoverDocument = gql`
    query ticketInfoForPopover($ticketId: ID!, $withContent: Boolean = false) {
  ticket(ticketId: $ticketId) {
    id
    internalId
    number
    title
    createdAt
    escalationAt
    firstResponseEscalationAt
    closeEscalationAt
    updateEscalationAt
    owner {
      id
      internalId
      firstname
      lastname
      fullname
    }
    customer {
      id
      internalId
      firstname
      lastname
      fullname
      image
      vip
      active
      outOfOffice
      outOfOfficeStartAt
      outOfOfficeEndAt
      email
    }
    organization {
      id
      internalId
      name
      vip
      active
    }
    stateColorCode
    state {
      id
      name
      stateType {
        id
        name
      }
    }
    group {
      id
      name
    }
    priority {
      id
      name
    }
    aiStoredSummary @include(if: $withContent) {
      customerRequest
      customerMood
      customerEmotion
    }
    checklist @include(if: $withContent) {
      id
      complete
      total
      completed
    }
    firstArticle @include(if: $withContent) {
      ...ticketPopoverArticle
    }
    lastArticle @include(if: $withContent) {
      ...ticketPopoverArticle
    }
  }
}
    ${TicketPopoverArticleFragmentDoc}`;
export function useTicketInfoForPopoverQuery(options: VueApolloComposable.useQuery.Options<Types.TicketInfoForPopoverQuery, Types.TicketInfoForPopoverQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketInfoForPopoverQuery, Types.TicketInfoForPopoverQueryVariables>(TicketInfoForPopoverDocument, options);
}
export function useTicketInfoForPopoverLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketInfoForPopoverQuery, Types.TicketInfoForPopoverQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketInfoForPopoverQuery, Types.TicketInfoForPopoverQueryVariables>(TicketInfoForPopoverDocument, options);
}
export type TicketInfoForPopoverQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketInfoForPopoverQuery, Types.TicketInfoForPopoverQueryVariables>;