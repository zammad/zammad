import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketAttributesFragmentDoc } from '../fragments/ticketAttributes.api';
import { ObjectAttributeValuesFragmentDoc } from '../../../../graphql/fragments/objectAttributeValues.api';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketCustomerUpdateDocument = gql`
    mutation ticketCustomerUpdate($ticketId: ID!, $input: TicketCustomerUpdateInput!) {
  ticketCustomerUpdate(ticketId: $ticketId, input: $input) {
    ticket {
      ...ticketAttributes
    }
    errors {
      ...errors
    }
  }
}
    ${TicketAttributesFragmentDoc}
${ObjectAttributeValuesFragmentDoc}
${ErrorsFragmentDoc}`;
export function useTicketCustomerUpdateMutation(options: VueApolloComposable.useMutation.Options<Types.TicketCustomerUpdateMutation, Types.TicketCustomerUpdateMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketCustomerUpdateMutation, Types.TicketCustomerUpdateMutationVariables>(TicketCustomerUpdateDocument, options);
}
export type TicketCustomerUpdateMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketCustomerUpdateMutation, Types.TicketCustomerUpdateMutationVariables>;