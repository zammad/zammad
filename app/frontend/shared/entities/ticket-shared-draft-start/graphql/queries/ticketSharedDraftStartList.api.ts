import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketSharedDraftStartAttributesFragmentDoc } from '../fragments/ticketSharedDraftStartAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketSharedDraftStartListDocument = gql`
    query ticketSharedDraftStartList($groupId: ID!) {
  ticketSharedDraftStartList(groupId: $groupId) {
    ...ticketSharedDraftStartAttributes
  }
}
    ${TicketSharedDraftStartAttributesFragmentDoc}`;
export function useTicketSharedDraftStartListQuery(options: VueApolloComposable.useQuery.Options<Types.TicketSharedDraftStartListQuery, Types.TicketSharedDraftStartListQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TicketSharedDraftStartListQuery, Types.TicketSharedDraftStartListQueryVariables>(TicketSharedDraftStartListDocument, options);
}
export function useTicketSharedDraftStartListLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketSharedDraftStartListQuery, Types.TicketSharedDraftStartListQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketSharedDraftStartListQuery, Types.TicketSharedDraftStartListQueryVariables>(TicketSharedDraftStartListDocument, options);
}
export type TicketSharedDraftStartListQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketSharedDraftStartListQuery, Types.TicketSharedDraftStartListQueryVariables>;