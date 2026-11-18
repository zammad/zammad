import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketExternalReferencesIdoitUpObjectRemoveDocument = gql`
    mutation ticketExternalReferencesIdoitUpObjectRemove($ticketId: ID!, $idoitUpObjectId: String!) {
  ticketExternalReferencesIdoitUpObjectRemove(
    ticketId: $ticketId
    idoitUpObjectId: $idoitUpObjectId
  ) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketExternalReferencesIdoitUpObjectRemoveMutation(options: VueApolloComposable.useMutation.Options<Types.TicketExternalReferencesIdoitUpObjectRemoveMutation, Types.TicketExternalReferencesIdoitUpObjectRemoveMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketExternalReferencesIdoitUpObjectRemoveMutation, Types.TicketExternalReferencesIdoitUpObjectRemoveMutationVariables>(TicketExternalReferencesIdoitUpObjectRemoveDocument, options);
}
export type TicketExternalReferencesIdoitUpObjectRemoveMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketExternalReferencesIdoitUpObjectRemoveMutation, Types.TicketExternalReferencesIdoitUpObjectRemoveMutationVariables>;