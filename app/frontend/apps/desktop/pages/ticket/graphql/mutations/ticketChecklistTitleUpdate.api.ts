import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketChecklistTitleUpdateDocument = gql`
    mutation ticketChecklistTitleUpdate($checklistId: ID!, $title: String) {
  ticketChecklistTitleUpdate(checklistId: $checklistId, title: $title) {
    checklist {
      id
      name
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketChecklistTitleUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketChecklistTitleUpdateMutation, Types.TicketChecklistTitleUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketChecklistTitleUpdateMutation, Types.TicketChecklistTitleUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketChecklistTitleUpdateMutation, Types.TicketChecklistTitleUpdateMutationVariables>(TicketChecklistTitleUpdateDocument, options);
}
export type TicketChecklistTitleUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketChecklistTitleUpdateMutation, Types.TicketChecklistTitleUpdateMutationVariables>;