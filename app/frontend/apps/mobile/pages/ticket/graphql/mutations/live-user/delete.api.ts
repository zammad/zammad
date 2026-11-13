import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useTicketLiveUserDeleteMutation(options: VueApolloComposable.useMutation.Options<Types.TicketLiveUserDeleteMutation, Types.TicketLiveUserDeleteMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketLiveUserDeleteMutation, Types.TicketLiveUserDeleteMutationVariables>(TicketLiveUserDeleteDocument, options);
}
export type TicketLiveUserDeleteMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketLiveUserDeleteMutation, Types.TicketLiveUserDeleteMutationVariables>;