import * as Types from '../../../../graphql/types';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketMergeDocument = gql`
    mutation ticketMerge($sourceTicketId: ID!, $targetTicketId: ID!) {
  ticketMerge(sourceTicketId: $sourceTicketId, targetTicketId: $targetTicketId) {
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketMergeMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketMergeMutation, Types.TicketMergeMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketMergeMutation, Types.TicketMergeMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketMergeMutation, Types.TicketMergeMutationVariables>(TicketMergeDocument, options);
}
export type TicketMergeMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketMergeMutation, Types.TicketMergeMutationVariables>;