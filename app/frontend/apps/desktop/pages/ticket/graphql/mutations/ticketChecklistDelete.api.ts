import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketChecklistDeleteDocument = gql`
    mutation ticketChecklistDelete($checklistId: ID!) {
  ticketChecklistDelete(checklistId: $checklistId) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketChecklistDeleteMutation(options: VueApolloComposable.useMutation.Options<Types.TicketChecklistDeleteMutation, Types.TicketChecklistDeleteMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketChecklistDeleteMutation, Types.TicketChecklistDeleteMutationVariables>(TicketChecklistDeleteDocument, options);
}
export type TicketChecklistDeleteMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketChecklistDeleteMutation, Types.TicketChecklistDeleteMutationVariables>;