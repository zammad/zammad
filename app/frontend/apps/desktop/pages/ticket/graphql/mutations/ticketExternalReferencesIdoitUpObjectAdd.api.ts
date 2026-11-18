import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { IdoitUpObjectAttributesFragmentDoc } from '../fragments/IdoitUpObjectAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketExternalReferencesIdoitUpObjectAddDocument = gql`
    mutation ticketExternalReferencesIdoitUpObjectAdd($idoitUpObjectIds: [String!]!, $ticketId: ID) {
  ticketExternalReferencesIdoitUpObjectAdd(
    idoitUpObjectIds: $idoitUpObjectIds
    ticketId: $ticketId
  ) {
    idoitUpObjects {
      ...IdoitUpObjectAttributes
    }
    errors {
      ...errors
    }
  }
}
    ${IdoitUpObjectAttributesFragmentDoc}
${ErrorsFragmentDoc}`;
export function useTicketExternalReferencesIdoitUpObjectAddMutation(options: VueApolloComposable.useMutation.Options<Types.TicketExternalReferencesIdoitUpObjectAddMutation, Types.TicketExternalReferencesIdoitUpObjectAddMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketExternalReferencesIdoitUpObjectAddMutation, Types.TicketExternalReferencesIdoitUpObjectAddMutationVariables>(TicketExternalReferencesIdoitUpObjectAddDocument, options);
}
export type TicketExternalReferencesIdoitUpObjectAddMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketExternalReferencesIdoitUpObjectAddMutation, Types.TicketExternalReferencesIdoitUpObjectAddMutationVariables>;