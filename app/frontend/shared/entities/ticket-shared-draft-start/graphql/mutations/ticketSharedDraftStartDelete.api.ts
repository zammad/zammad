import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketSharedDraftStartDeleteDocument = gql`
    mutation ticketSharedDraftStartDelete($sharedDraftId: ID!) {
  ticketSharedDraftStartDelete(sharedDraftId: $sharedDraftId) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketSharedDraftStartDeleteMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketSharedDraftStartDeleteMutation, Types.TicketSharedDraftStartDeleteMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketSharedDraftStartDeleteMutation, Types.TicketSharedDraftStartDeleteMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketSharedDraftStartDeleteMutation, Types.TicketSharedDraftStartDeleteMutationVariables>(TicketSharedDraftStartDeleteDocument, options);
}
export type TicketSharedDraftStartDeleteMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketSharedDraftStartDeleteMutation, Types.TicketSharedDraftStartDeleteMutationVariables>;