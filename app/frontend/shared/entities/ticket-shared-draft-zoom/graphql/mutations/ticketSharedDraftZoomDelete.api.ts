import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketSharedDraftZoomDeleteDocument = gql`
    mutation ticketSharedDraftZoomDelete($sharedDraftId: ID!) {
  ticketSharedDraftZoomDelete(sharedDraftId: $sharedDraftId) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketSharedDraftZoomDeleteMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketSharedDraftZoomDeleteMutation, Types.TicketSharedDraftZoomDeleteMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketSharedDraftZoomDeleteMutation, Types.TicketSharedDraftZoomDeleteMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketSharedDraftZoomDeleteMutation, Types.TicketSharedDraftZoomDeleteMutationVariables>(TicketSharedDraftZoomDeleteDocument, options);
}
export type TicketSharedDraftZoomDeleteMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketSharedDraftZoomDeleteMutation, Types.TicketSharedDraftZoomDeleteMutationVariables>;