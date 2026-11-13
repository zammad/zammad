import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketChecklistItemDeleteDocument = gql`
    mutation ticketChecklistItemDelete($checklistId: ID!, $checklistItemId: ID!) {
  ticketChecklistItemDelete(
    checklistId: $checklistId
    checklistItemId: $checklistItemId
  ) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketChecklistItemDeleteMutation(options: VueApolloComposable.useMutation.Options<Types.TicketChecklistItemDeleteMutation, Types.TicketChecklistItemDeleteMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketChecklistItemDeleteMutation, Types.TicketChecklistItemDeleteMutationVariables>(TicketChecklistItemDeleteDocument, options);
}
export type TicketChecklistItemDeleteMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketChecklistItemDeleteMutation, Types.TicketChecklistItemDeleteMutationVariables>;