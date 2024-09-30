import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketChecklistItemUpsertDocument = gql`
    mutation ticketChecklistItemUpsert($checklistId: ID!, $checklistItemId: ID, $input: TicketChecklistItemInput!) {
  ticketChecklistItemUpsert(
    checklistId: $checklistId
    checklistItemId: $checklistItemId
    input: $input
  ) {
    checklistItem {
      id
      text
      checked
      ticketReference {
        ticket {
          id
          internalId
          number
          title
          state {
            id
            name
          }
          stateColorCode
        }
      }
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketChecklistItemUpsertMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketChecklistItemUpsertMutation, Types.TicketChecklistItemUpsertMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketChecklistItemUpsertMutation, Types.TicketChecklistItemUpsertMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketChecklistItemUpsertMutation, Types.TicketChecklistItemUpsertMutationVariables>(TicketChecklistItemUpsertDocument, options);
}
export type TicketChecklistItemUpsertMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketChecklistItemUpsertMutation, Types.TicketChecklistItemUpsertMutationVariables>;