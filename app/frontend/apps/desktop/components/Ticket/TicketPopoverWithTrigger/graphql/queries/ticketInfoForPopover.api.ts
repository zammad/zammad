import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketInfoForPopoverDocument = gql`
    query ticketInfoForPopover($ticketId: ID!) {
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
  }
}
    `;
export function useTicketInfoForPopoverQuery(variables: Types.TicketInfoForPopoverQueryVariables | VueCompositionApi.Ref<Types.TicketInfoForPopoverQueryVariables> | ReactiveFunction<Types.TicketInfoForPopoverQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketInfoForPopoverQuery, Types.TicketInfoForPopoverQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketInfoForPopoverQuery, Types.TicketInfoForPopoverQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketInfoForPopoverQuery, Types.TicketInfoForPopoverQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketInfoForPopoverQuery, Types.TicketInfoForPopoverQueryVariables>(TicketInfoForPopoverDocument, variables, options);
}
export function useTicketInfoForPopoverLazyQuery(variables?: Types.TicketInfoForPopoverQueryVariables | VueCompositionApi.Ref<Types.TicketInfoForPopoverQueryVariables> | ReactiveFunction<Types.TicketInfoForPopoverQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketInfoForPopoverQuery, Types.TicketInfoForPopoverQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketInfoForPopoverQuery, Types.TicketInfoForPopoverQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketInfoForPopoverQuery, Types.TicketInfoForPopoverQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketInfoForPopoverQuery, Types.TicketInfoForPopoverQueryVariables>(TicketInfoForPopoverDocument, variables, options);
}
export type TicketInfoForPopoverQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketInfoForPopoverQuery, Types.TicketInfoForPopoverQueryVariables>;