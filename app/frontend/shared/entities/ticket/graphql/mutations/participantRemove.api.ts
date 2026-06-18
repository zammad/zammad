import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketParticipantRemoveDocument = gql`
    mutation ticketParticipantRemove($ticketId: ID!, $userId: ID!) {
  ticketParticipantRemove(ticketId: $ticketId, userId: $userId) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketParticipantRemoveMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketParticipantRemoveMutation, Types.TicketParticipantRemoveMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketParticipantRemoveMutation, Types.TicketParticipantRemoveMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketParticipantRemoveMutation, Types.TicketParticipantRemoveMutationVariables>(TicketParticipantRemoveDocument, options);
}
export type TicketParticipantRemoveMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketParticipantRemoveMutation, Types.TicketParticipantRemoveMutationVariables>;