import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketAttributesFragmentDoc } from '../fragments/ticketAttributes.api';
import { ObjectAttributeValuesFragmentDoc } from '../../../../graphql/fragments/objectAttributeValues.api';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable/compat';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useTicketTitleUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketTitleUpdateMutation, Types.TicketTitleUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketTitleUpdateMutation, Types.TicketTitleUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketTitleUpdateMutation, Types.TicketTitleUpdateMutationVariables>(TicketTitleUpdateDocument, options);
}
export type TicketTitleUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketTitleUpdateMutation, Types.TicketTitleUpdateMutationVariables>;