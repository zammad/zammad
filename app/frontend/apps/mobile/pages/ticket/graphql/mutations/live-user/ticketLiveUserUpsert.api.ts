import * as Types from '../../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketLiveUserUpsertDocument = gql`
    mutation ticketLiveUserUpsert($id: ID!, $app: EnumTaskbarApp!, $editing: Boolean!) {
  ticketLiveUserUpsert(id: $id, app: $app, editing: $editing) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketLiveUserUpsertMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketLiveUserUpsertMutation, Types.TicketLiveUserUpsertMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketLiveUserUpsertMutation, Types.TicketLiveUserUpsertMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketLiveUserUpsertMutation, Types.TicketLiveUserUpsertMutationVariables>(TicketLiveUserUpsertDocument, options);
}
export type TicketLiveUserUpsertMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketLiveUserUpsertMutation, Types.TicketLiveUserUpsertMutationVariables>;