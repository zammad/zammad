import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketSharedDraftStartAttributesFragmentDoc } from '../fragments/ticketSharedDraftStartAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketSharedDraftStartSingleDocument = gql`
    query ticketSharedDraftStartSingle($sharedDraftId: ID!) {
  ticketSharedDraftStartSingle(sharedDraftId: $sharedDraftId) {
    ...ticketSharedDraftStartAttributes
    content
  }
}
    ${TicketSharedDraftStartAttributesFragmentDoc}`;
export function useTicketSharedDraftStartSingleQuery(variables: Types.TicketSharedDraftStartSingleQueryVariables | VueCompositionApi.Ref<Types.TicketSharedDraftStartSingleQueryVariables> | ReactiveFunction<Types.TicketSharedDraftStartSingleQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketSharedDraftStartSingleQuery, Types.TicketSharedDraftStartSingleQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketSharedDraftStartSingleQuery, Types.TicketSharedDraftStartSingleQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketSharedDraftStartSingleQuery, Types.TicketSharedDraftStartSingleQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketSharedDraftStartSingleQuery, Types.TicketSharedDraftStartSingleQueryVariables>(TicketSharedDraftStartSingleDocument, variables, options);
}
export function useTicketSharedDraftStartSingleLazyQuery(variables?: Types.TicketSharedDraftStartSingleQueryVariables | VueCompositionApi.Ref<Types.TicketSharedDraftStartSingleQueryVariables> | ReactiveFunction<Types.TicketSharedDraftStartSingleQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketSharedDraftStartSingleQuery, Types.TicketSharedDraftStartSingleQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketSharedDraftStartSingleQuery, Types.TicketSharedDraftStartSingleQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketSharedDraftStartSingleQuery, Types.TicketSharedDraftStartSingleQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketSharedDraftStartSingleQuery, Types.TicketSharedDraftStartSingleQueryVariables>(TicketSharedDraftStartSingleDocument, variables, options);
}
export type TicketSharedDraftStartSingleQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketSharedDraftStartSingleQuery, Types.TicketSharedDraftStartSingleQueryVariables>;