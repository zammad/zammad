import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketExternalReferencesSnipeitAssetRemoveDocument = gql`
    mutation ticketExternalReferencesSnipeitAssetRemove($ticketId: ID!, $snipeitAssetId: Int!) {
  ticketExternalReferencesSnipeitAssetRemove(
    ticketId: $ticketId
    snipeitAssetId: $snipeitAssetId
  ) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketExternalReferencesSnipeitAssetRemoveMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketExternalReferencesSnipeitAssetRemoveMutation, Types.TicketExternalReferencesSnipeitAssetRemoveMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketExternalReferencesSnipeitAssetRemoveMutation, Types.TicketExternalReferencesSnipeitAssetRemoveMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketExternalReferencesSnipeitAssetRemoveMutation, Types.TicketExternalReferencesSnipeitAssetRemoveMutationVariables>(TicketExternalReferencesSnipeitAssetRemoveDocument, options);
}
export type TicketExternalReferencesSnipeitAssetRemoveMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketExternalReferencesSnipeitAssetRemoveMutation, Types.TicketExternalReferencesSnipeitAssetRemoveMutationVariables>;