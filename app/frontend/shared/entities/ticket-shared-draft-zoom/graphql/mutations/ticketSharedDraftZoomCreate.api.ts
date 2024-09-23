import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketSharedDraftZoomAttributesFragmentDoc } from '../fragments/ticketSharedDraftZoomAttributes.api';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketSharedDraftZoomCreateDocument = gql`
    mutation ticketSharedDraftZoomCreate($input: TicketSharedDraftZoomInput!) {
  ticketSharedDraftZoomCreate(input: $input) {
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
export function useTicketSharedDraftZoomCreateMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketSharedDraftZoomCreateMutation, Types.TicketSharedDraftZoomCreateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketSharedDraftZoomCreateMutation, Types.TicketSharedDraftZoomCreateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketSharedDraftZoomCreateMutation, Types.TicketSharedDraftZoomCreateMutationVariables>(TicketSharedDraftZoomCreateDocument, options);
}
export type TicketSharedDraftZoomCreateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketSharedDraftZoomCreateMutation, Types.TicketSharedDraftZoomCreateMutationVariables>;