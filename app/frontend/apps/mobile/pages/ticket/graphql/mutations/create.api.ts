import * as Types from '../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import { TicketAttributesFragmentDoc } from '../fragments/ticketAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketCreateDocument = gql`
    mutation ticketCreate($input: TicketCreateInput!) {
  ticketCreate(input: $input) {
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
export function useTicketCreateMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketCreateMutation, Types.TicketCreateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketCreateMutation, Types.TicketCreateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketCreateMutation, Types.TicketCreateMutationVariables>(TicketCreateDocument, options);
}
export type TicketCreateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketCreateMutation, Types.TicketCreateMutationVariables>;