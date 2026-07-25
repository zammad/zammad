import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { SnipeitAssetAttributesFragmentDoc } from '../fragments/SnipeitAssetAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketExternalReferencesSnipeitAssetAddDocument = gql`
    mutation ticketExternalReferencesSnipeitAssetAdd($snipeitAssetIds: [Int!]!, $ticketId: ID) {
  ticketExternalReferencesSnipeitAssetAdd(
    snipeitAssetIds: $snipeitAssetIds
    ticketId: $ticketId
  ) {
    snipeitAssets {
      ...SnipeitAssetAttributes
    }
    errors {
      ...errors
    }
  }
}
    ${SnipeitAssetAttributesFragmentDoc}
${ErrorsFragmentDoc}`;
export function useTicketExternalReferencesSnipeitAssetAddMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketExternalReferencesSnipeitAssetAddMutation, Types.TicketExternalReferencesSnipeitAssetAddMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketExternalReferencesSnipeitAssetAddMutation, Types.TicketExternalReferencesSnipeitAssetAddMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketExternalReferencesSnipeitAssetAddMutation, Types.TicketExternalReferencesSnipeitAssetAddMutationVariables>(TicketExternalReferencesSnipeitAssetAddDocument, options);
}
export type TicketExternalReferencesSnipeitAssetAddMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketExternalReferencesSnipeitAssetAddMutation, Types.TicketExternalReferencesSnipeitAssetAddMutationVariables>;