import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketChecklistAddDocument = gql`
    mutation ticketChecklistAdd($ticketId: ID, $ticketInternalId: Int, $ticketNumber: String, $templateId: ID) {
  ticketChecklistAdd(
    ticket: {ticketId: $ticketId, ticketInternalId: $ticketInternalId, ticketNumber: $ticketNumber}
    templateId: $templateId
  ) {
    checklist {
      id
      name
      items {
        id
        text
        checked
      }
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketChecklistAddMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketChecklistAddMutation, Types.TicketChecklistAddMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketChecklistAddMutation, Types.TicketChecklistAddMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketChecklistAddMutation, Types.TicketChecklistAddMutationVariables>(TicketChecklistAddDocument, options);
}
export type TicketChecklistAddMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketChecklistAddMutation, Types.TicketChecklistAddMutationVariables>;