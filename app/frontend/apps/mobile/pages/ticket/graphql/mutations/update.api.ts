import * as Types from '../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import { TicketAttributesFragmentDoc } from '../fragments/ticketAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketUpdateDocument = gql`
    mutation ticketUpdate($ticketId: ID!, $input: TicketUpdateInput!) {
  ticketUpdate(ticketId: $ticketId, input: $input) {
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
export function useTicketUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketUpdateMutation, Types.TicketUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketUpdateMutation, Types.TicketUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketUpdateMutation, Types.TicketUpdateMutationVariables>(TicketUpdateDocument, options);
}
export type TicketUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketUpdateMutation, Types.TicketUpdateMutationVariables>;