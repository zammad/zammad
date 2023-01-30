import * as Types from '../../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketLiveUserDeleteDocument = gql`
    mutation ticketLiveUserDelete($id: ID!, $app: EnumTaskbarApp!) {
  ticketLiveUserDelete(id: $id, app: $app) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketLiveUserDeleteMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketLiveUserDeleteMutation, Types.TicketLiveUserDeleteMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketLiveUserDeleteMutation, Types.TicketLiveUserDeleteMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketLiveUserDeleteMutation, Types.TicketLiveUserDeleteMutationVariables>(TicketLiveUserDeleteDocument, options);
}
export type TicketLiveUserDeleteMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketLiveUserDeleteMutation, Types.TicketLiveUserDeleteMutationVariables>;