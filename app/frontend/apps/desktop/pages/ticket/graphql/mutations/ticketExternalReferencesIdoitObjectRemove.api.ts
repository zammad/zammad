import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketExternalReferencesIdoitObjectRemoveDocument = gql`
    mutation ticketExternalReferencesIdoitObjectRemove($ticketId: ID!, $idoitObjectId: Int!) {
  ticketExternalReferencesIdoitObjectRemove(
    ticketId: $ticketId
    idoitObjectId: $idoitObjectId
  ) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketExternalReferencesIdoitObjectRemoveMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketExternalReferencesIdoitObjectRemoveMutation, Types.TicketExternalReferencesIdoitObjectRemoveMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketExternalReferencesIdoitObjectRemoveMutation, Types.TicketExternalReferencesIdoitObjectRemoveMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketExternalReferencesIdoitObjectRemoveMutation, Types.TicketExternalReferencesIdoitObjectRemoveMutationVariables>(TicketExternalReferencesIdoitObjectRemoveDocument, options);
}
export type TicketExternalReferencesIdoitObjectRemoveMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketExternalReferencesIdoitObjectRemoveMutation, Types.TicketExternalReferencesIdoitObjectRemoveMutationVariables>;