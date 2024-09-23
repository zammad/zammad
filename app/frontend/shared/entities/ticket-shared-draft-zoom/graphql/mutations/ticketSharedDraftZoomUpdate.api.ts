import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketSharedDraftZoomAttributesFragmentDoc } from '../fragments/ticketSharedDraftZoomAttributes.api';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketSharedDraftZoomUpdateDocument = gql`
    mutation ticketSharedDraftZoomUpdate($sharedDraftId: ID!, $input: TicketSharedDraftZoomInput!) {
  ticketSharedDraftZoomUpdate(input: $input, sharedDraftId: $sharedDraftId) {
    sharedDraft {
      ...ticketSharedDraftZoomAttributes
    }
    errors {
      ...errors
    }
  }
}
    ${TicketSharedDraftZoomAttributesFragmentDoc}
${ErrorsFragmentDoc}`;
export function useTicketSharedDraftZoomUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketSharedDraftZoomUpdateMutation, Types.TicketSharedDraftZoomUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketSharedDraftZoomUpdateMutation, Types.TicketSharedDraftZoomUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketSharedDraftZoomUpdateMutation, Types.TicketSharedDraftZoomUpdateMutationVariables>(TicketSharedDraftZoomUpdateDocument, options);
}
export type TicketSharedDraftZoomUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketSharedDraftZoomUpdateMutation, Types.TicketSharedDraftZoomUpdateMutationVariables>;