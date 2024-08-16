import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useTicketChecklistDeleteMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketChecklistDeleteMutation, Types.TicketChecklistDeleteMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketChecklistDeleteMutation, Types.TicketChecklistDeleteMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketChecklistDeleteMutation, Types.TicketChecklistDeleteMutationVariables>(TicketChecklistDeleteDocument, options);
}
export type TicketChecklistDeleteMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketChecklistDeleteMutation, Types.TicketChecklistDeleteMutationVariables>;