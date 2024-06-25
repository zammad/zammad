import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketAttributesFragmentDoc } from '../fragments/ticketAttributes.api';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
${ErrorsFragmentDoc}`;
export function useTicketCustomerUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketCustomerUpdateMutation, Types.TicketCustomerUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketCustomerUpdateMutation, Types.TicketCustomerUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketCustomerUpdateMutation, Types.TicketCustomerUpdateMutationVariables>(TicketCustomerUpdateDocument, options);
}
export type TicketCustomerUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketCustomerUpdateMutation, Types.TicketCustomerUpdateMutationVariables>;