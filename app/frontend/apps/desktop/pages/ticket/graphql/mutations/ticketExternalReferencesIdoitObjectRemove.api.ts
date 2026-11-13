import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useTicketExternalReferencesIdoitObjectRemoveMutation(options: VueApolloComposable.useMutation.Options<Types.TicketExternalReferencesIdoitObjectRemoveMutation, Types.TicketExternalReferencesIdoitObjectRemoveMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketExternalReferencesIdoitObjectRemoveMutation, Types.TicketExternalReferencesIdoitObjectRemoveMutationVariables>(TicketExternalReferencesIdoitObjectRemoveDocument, options);
}
export type TicketExternalReferencesIdoitObjectRemoveMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketExternalReferencesIdoitObjectRemoveMutation, Types.TicketExternalReferencesIdoitObjectRemoveMutationVariables>;