import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketChecklistAddDocument = gql`
    mutation ticketChecklistAdd($ticketId: ID!, $templateId: ID, $createFirstItem: Boolean) {
  ticketChecklistAdd(
    ticketId: $ticketId
    templateId: $templateId
    createFirstItem: $createFirstItem
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
export function useTicketChecklistAddMutation(options: VueApolloComposable.useMutation.Options<Types.TicketChecklistAddMutation, Types.TicketChecklistAddMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketChecklistAddMutation, Types.TicketChecklistAddMutationVariables>(TicketChecklistAddDocument, options);
}
export type TicketChecklistAddMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketChecklistAddMutation, Types.TicketChecklistAddMutationVariables>;