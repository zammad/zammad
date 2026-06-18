import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketParticipantAddDocument = gql`
    mutation ticketParticipantAdd($ticketId: ID!, $userId: ID!) {
  ticketParticipantAdd(ticketId: $ticketId, userId: $userId) {
    participant {
      id
      firstname
      lastname
      email
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketParticipantAddMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketParticipantAddMutation, Types.TicketParticipantAddMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketParticipantAddMutation, Types.TicketParticipantAddMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketParticipantAddMutation, Types.TicketParticipantAddMutationVariables>(TicketParticipantAddDocument, options);
}
export type TicketParticipantAddMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketParticipantAddMutation, Types.TicketParticipantAddMutationVariables>;