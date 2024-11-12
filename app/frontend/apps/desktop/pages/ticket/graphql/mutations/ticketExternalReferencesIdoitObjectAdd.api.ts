import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { IdoitObjectAttributesFragmentDoc } from '../fragments/IdoitObjectAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketExternalReferencesIdoitObjectAddDocument = gql`
    mutation ticketExternalReferencesIdoitObjectAdd($idoitObjectIds: [Int!]!, $ticketId: ID) {
  ticketExternalReferencesIdoitObjectAdd(
    idoitObjectIds: $idoitObjectIds
    ticketId: $ticketId
  ) {
    idoitObjects {
      ...IdoitObjectAttributes
    }
    errors {
      ...errors
    }
  }
}
    ${IdoitObjectAttributesFragmentDoc}
${ErrorsFragmentDoc}`;
export function useTicketExternalReferencesIdoitObjectAddMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketExternalReferencesIdoitObjectAddMutation, Types.TicketExternalReferencesIdoitObjectAddMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketExternalReferencesIdoitObjectAddMutation, Types.TicketExternalReferencesIdoitObjectAddMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketExternalReferencesIdoitObjectAddMutation, Types.TicketExternalReferencesIdoitObjectAddMutationVariables>(TicketExternalReferencesIdoitObjectAddDocument, options);
}
export type TicketExternalReferencesIdoitObjectAddMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketExternalReferencesIdoitObjectAddMutation, Types.TicketExternalReferencesIdoitObjectAddMutationVariables>;