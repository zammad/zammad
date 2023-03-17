import * as Types from '../types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketSignatureDocument = gql`
    query ticketSignature($groupId: ID!, $ticketId: ID) {
  ticketSignature(groupId: $groupId) {
    id
    renderedBody(ticketId: $ticketId)
  }
}
    `;
export function useTicketSignatureQuery(variables: Types.TicketSignatureQueryVariables | VueCompositionApi.Ref<Types.TicketSignatureQueryVariables> | ReactiveFunction<Types.TicketSignatureQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketSignatureQuery, Types.TicketSignatureQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketSignatureQuery, Types.TicketSignatureQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketSignatureQuery, Types.TicketSignatureQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketSignatureQuery, Types.TicketSignatureQueryVariables>(TicketSignatureDocument, variables, options);
}
export function useTicketSignatureLazyQuery(variables: Types.TicketSignatureQueryVariables | VueCompositionApi.Ref<Types.TicketSignatureQueryVariables> | ReactiveFunction<Types.TicketSignatureQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketSignatureQuery, Types.TicketSignatureQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketSignatureQuery, Types.TicketSignatureQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketSignatureQuery, Types.TicketSignatureQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketSignatureQuery, Types.TicketSignatureQueryVariables>(TicketSignatureDocument, variables, options);
}
export type TicketSignatureQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketSignatureQuery, Types.TicketSignatureQueryVariables>;