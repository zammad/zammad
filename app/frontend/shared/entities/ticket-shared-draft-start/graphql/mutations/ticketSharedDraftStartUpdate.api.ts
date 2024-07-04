import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketSharedDraftStartAttributesFragmentDoc } from '../fragments/ticketSharedDraftStartAttributes.api';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketSharedDraftStartUpdateDocument = gql`
    mutation ticketSharedDraftStartUpdate($sharedDraftId: ID!, $input: TicketSharedDraftStartInput!) {
  ticketSharedDraftStartUpdate(input: $input, sharedDraftId: $sharedDraftId) {
    sharedDraft {
      ...ticketSharedDraftStartAttributes
    }
    errors {
      ...errors
    }
  }
}
    ${TicketSharedDraftStartAttributesFragmentDoc}
${ErrorsFragmentDoc}`;
export function useTicketSharedDraftStartUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketSharedDraftStartUpdateMutation, Types.TicketSharedDraftStartUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketSharedDraftStartUpdateMutation, Types.TicketSharedDraftStartUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketSharedDraftStartUpdateMutation, Types.TicketSharedDraftStartUpdateMutationVariables>(TicketSharedDraftStartUpdateDocument, options);
}
export type TicketSharedDraftStartUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketSharedDraftStartUpdateMutation, Types.TicketSharedDraftStartUpdateMutationVariables>;