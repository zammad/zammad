import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketAttributesFragmentDoc } from '../fragments/ticketAttributes.api';
import { ObjectAttributeValuesFragmentDoc } from '../../../../graphql/fragments/objectAttributeValues.api';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketTitleUpdateDocument = gql`
    mutation ticketTitleUpdate($ticketId: ID!, $title: String!) {
  ticketTitleUpdate(ticketId: $ticketId, title: $title) {
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
export function useTicketTitleUpdateMutation(options: VueApolloComposable.useMutation.Options<Types.TicketTitleUpdateMutation, Types.TicketTitleUpdateMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketTitleUpdateMutation, Types.TicketTitleUpdateMutationVariables>(TicketTitleUpdateDocument, options);
}
export type TicketTitleUpdateMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketTitleUpdateMutation, Types.TicketTitleUpdateMutationVariables>;