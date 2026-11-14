import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketSharedDraftZoomAttributesFragmentDoc } from '../fragments/ticketSharedDraftZoomAttributes.api';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useTicketSharedDraftZoomUpdateMutation(options: VueApolloComposable.useMutation.Options<Types.TicketSharedDraftZoomUpdateMutation, Types.TicketSharedDraftZoomUpdateMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketSharedDraftZoomUpdateMutation, Types.TicketSharedDraftZoomUpdateMutationVariables>(TicketSharedDraftZoomUpdateDocument, options);
}
export type TicketSharedDraftZoomUpdateMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketSharedDraftZoomUpdateMutation, Types.TicketSharedDraftZoomUpdateMutationVariables>;