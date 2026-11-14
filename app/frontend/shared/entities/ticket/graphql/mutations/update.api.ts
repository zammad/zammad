import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketAttributesFragmentDoc } from '../fragments/ticketAttributes.api';
import { ObjectAttributeValuesFragmentDoc } from '../../../../graphql/fragments/objectAttributeValues.api';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketUpdateDocument = gql`
    mutation ticketUpdate($ticketId: ID!, $input: TicketUpdateInput!, $meta: TicketUpdateMetaInput!) {
  ticketUpdate(ticketId: $ticketId, input: $input, meta: $meta) {
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
export function useTicketUpdateMutation(options: VueApolloComposable.useMutation.Options<Types.TicketUpdateMutation, Types.TicketUpdateMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketUpdateMutation, Types.TicketUpdateMutationVariables>(TicketUpdateDocument, options);
}
export type TicketUpdateMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketUpdateMutation, Types.TicketUpdateMutationVariables>;