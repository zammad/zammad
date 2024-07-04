import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketSharedDraftStartAttributesFragmentDoc } from '../fragments/ticketSharedDraftStartAttributes.api';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketSharedDraftStartCreateDocument = gql`
    mutation ticketSharedDraftStartCreate($name: String!, $input: TicketSharedDraftStartInput!) {
  ticketSharedDraftStartCreate(name: $name, input: $input) {
    sharedDraft {
      ...ticketSharedDraftStartAttributes
    }
    errors {
      ...errors
    }
  }
}
    ${TicketSharedDraftStartAttributesFragmentDoc}
${ErrorsFragmentDoc}`;
export function useTicketSharedDraftStartCreateMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketSharedDraftStartCreateMutation, Types.TicketSharedDraftStartCreateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketSharedDraftStartCreateMutation, Types.TicketSharedDraftStartCreateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketSharedDraftStartCreateMutation, Types.TicketSharedDraftStartCreateMutationVariables>(TicketSharedDraftStartCreateDocument, options);
}
export type TicketSharedDraftStartCreateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketSharedDraftStartCreateMutation, Types.TicketSharedDraftStartCreateMutationVariables>;