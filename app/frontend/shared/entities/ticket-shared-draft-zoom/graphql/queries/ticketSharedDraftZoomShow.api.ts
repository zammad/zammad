import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketSharedDraftZoomAttributesFragmentDoc } from '../fragments/ticketSharedDraftZoomAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketSharedDraftZoomShowDocument = gql`
    query ticketSharedDraftZoomShow($sharedDraftId: ID!) {
  ticketSharedDraftZoomShow(sharedDraftId: $sharedDraftId) {
    ...ticketSharedDraftZoomAttributes
  }
}
    ${TicketSharedDraftZoomAttributesFragmentDoc}`;
export function useTicketSharedDraftZoomShowQuery(variables: Types.TicketSharedDraftZoomShowQueryVariables | VueCompositionApi.Ref<Types.TicketSharedDraftZoomShowQueryVariables> | ReactiveFunction<Types.TicketSharedDraftZoomShowQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketSharedDraftZoomShowQuery, Types.TicketSharedDraftZoomShowQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketSharedDraftZoomShowQuery, Types.TicketSharedDraftZoomShowQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketSharedDraftZoomShowQuery, Types.TicketSharedDraftZoomShowQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketSharedDraftZoomShowQuery, Types.TicketSharedDraftZoomShowQueryVariables>(TicketSharedDraftZoomShowDocument, variables, options);
}
export function useTicketSharedDraftZoomShowLazyQuery(variables?: Types.TicketSharedDraftZoomShowQueryVariables | VueCompositionApi.Ref<Types.TicketSharedDraftZoomShowQueryVariables> | ReactiveFunction<Types.TicketSharedDraftZoomShowQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketSharedDraftZoomShowQuery, Types.TicketSharedDraftZoomShowQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketSharedDraftZoomShowQuery, Types.TicketSharedDraftZoomShowQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketSharedDraftZoomShowQuery, Types.TicketSharedDraftZoomShowQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketSharedDraftZoomShowQuery, Types.TicketSharedDraftZoomShowQueryVariables>(TicketSharedDraftZoomShowDocument, variables, options);
}
export type TicketSharedDraftZoomShowQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketSharedDraftZoomShowQuery, Types.TicketSharedDraftZoomShowQueryVariables>;