import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketSharedDraftStartAttributesFragmentDoc } from '../fragments/ticketSharedDraftStartAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketSharedDraftStartListDocument = gql`
    query ticketSharedDraftStartList($groupId: ID!) {
  ticketSharedDraftStartList(groupId: $groupId) {
    ...ticketSharedDraftStartAttributes
  }
}
    ${TicketSharedDraftStartAttributesFragmentDoc}`;
export function useTicketSharedDraftStartListQuery(variables: Types.TicketSharedDraftStartListQueryVariables | VueCompositionApi.Ref<Types.TicketSharedDraftStartListQueryVariables> | ReactiveFunction<Types.TicketSharedDraftStartListQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketSharedDraftStartListQuery, Types.TicketSharedDraftStartListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketSharedDraftStartListQuery, Types.TicketSharedDraftStartListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketSharedDraftStartListQuery, Types.TicketSharedDraftStartListQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketSharedDraftStartListQuery, Types.TicketSharedDraftStartListQueryVariables>(TicketSharedDraftStartListDocument, variables, options);
}
export function useTicketSharedDraftStartListLazyQuery(variables?: Types.TicketSharedDraftStartListQueryVariables | VueCompositionApi.Ref<Types.TicketSharedDraftStartListQueryVariables> | ReactiveFunction<Types.TicketSharedDraftStartListQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketSharedDraftStartListQuery, Types.TicketSharedDraftStartListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketSharedDraftStartListQuery, Types.TicketSharedDraftStartListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketSharedDraftStartListQuery, Types.TicketSharedDraftStartListQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketSharedDraftStartListQuery, Types.TicketSharedDraftStartListQueryVariables>(TicketSharedDraftStartListDocument, variables, options);
}
export type TicketSharedDraftStartListQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketSharedDraftStartListQuery, Types.TicketSharedDraftStartListQueryVariables>;